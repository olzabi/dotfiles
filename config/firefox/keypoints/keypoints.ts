// Keypoints dataset tooling for the Firefox highlighter (config/firefox/userscripts/keypoints.user.js).
//   keypoints serve   local collector: the userscript POSTs every highlighted page here, and installs/updates from here
//   keypoints label   teacher model marks key sentences on collected pages (nightly timer)
//   keypoints stats   what has been collected and labelled so far
// Data: $KEYPOINTS_DIR (default ~/.local/share/keypoints): pages.jsonl (raw), labels.jsonl (teacher).
// Training a small in-browser model from labels.jsonl comes later.
import { appendFileSync, existsSync, mkdirSync, readFileSync } from 'node:fs';
import { createServer } from 'node:http';
import { homedir } from 'node:os';
import { join } from 'node:path';
import { execFileSync } from 'node:child_process';

const DIR = process.env.KEYPOINTS_DIR || join(homedir(), '.local/share/keypoints');
const PORT = Number(process.env.KEYPOINTS_PORT || 11500);
const OLLAMA = process.env.KEYPOINTS_OLLAMA || 'http://127.0.0.1:11434'; // not OLLAMA_HOST: it is often set without a scheme
// MoE, 3B active: faster than qwen3:14b once loaded and better on reviews (2026-11-13 test). Thinking made picks worse.
const TEACHER = process.env.KEYPOINTS_TEACHER || 'qwen3:30b-a3b';
const BUDGET_MS = Number(process.env.KEYPOINTS_BUDGET_MIN || 120) * 60_000; // per run; the rest waits for the next one
const RATIO = 0.2; // keep in sync with the userscript
const MAX_BODY = 4 << 20;
const PAGES = join(DIR, 'pages.jsonl');
const USERSCRIPT = join(import.meta.dirname, '../userscripts/keypoints.user.js');
const LABELS = join(DIR, 'labels.jsonl');
const SYSTEM =
  'You mark key sentences for a speed reader. Given numbered sentences, return the indices of the few ' +
  'sentences that carry the main points: core claims, conclusions, definitions, decisions, key numbers. ' +
  'Skip examples, filler, transitions and repetition. If the text is several posts by different people ' +
  "(reviews, comments, answers), pick each substantial post's verdict or strongest reason."; // same as the userscript

export type Page = { url: string; title: string; lang: string; at: string; model: string; chunks: { sentences: string[]; picks: number[] }[] };

const readJsonl = <T>(file: string): T[] =>
  existsSync(file) ? readFileSync(file, 'utf8').split('\n').filter(Boolean).map((l) => JSON.parse(l) as T) : [];

// Trust boundary: anything on the machine (or a web page via fetch) can reach the port.
export function validPage(p: any): p is Page {
  return (
    p && typeof p.url === 'string' && /^https?:\/\//.test(p.url) && typeof p.title === 'string' && typeof p.lang === 'string' &&
    typeof p.model === 'string' && Array.isArray(p.chunks) && p.chunks.length > 0 &&
    p.chunks.every((c: any) => Array.isArray(c?.sentences) && c.sentences.every((s: any) => typeof s === 'string') &&
      Array.isArray(c.picks) && c.picks.every((i: any) => Number.isInteger(i) && i >= 0 && i < c.sentences.length))
  );
}

function serve() {
  mkdirSync(DIR, { recursive: true, mode: 0o700 }); // private: holds text of everything you read
  createServer((req, res) => {
    // A custom header forces a CORS preflight on web-page fetches, which we never answer;
    // GM_xmlhttpRequest is not subject to CORS. (Origin is unreliable: Violentmonkey may forward the page's.)
    // Violentmonkey installs from and checks for updates at this URL (bump @version to ship).
    if (req.method === 'GET' && req.url === '/keypoints.user.js')
      return res.writeHead(200, { 'Content-Type': 'text/javascript' }).end(readFileSync(USERSCRIPT));
    if (req.method !== 'POST' || req.url !== '/pages') return res.writeHead(404).end();
    if (req.headers['x-keypoints'] !== '1') return console.warn(`keypoints: 403 origin=${req.headers.origin}`), res.writeHead(403).end();
    let body = '';
    req.on('data', (d) => {
      body += d;
      if (body.length > MAX_BODY) res.writeHead(413).end(), req.destroy();
    });
    req.on('end', () => {
      if (res.writableEnded) return;
      let page;
      try {
        page = JSON.parse(body);
      } catch {
        return res.writeHead(400).end('bad json');
      }
      if (!validPage(page)) return console.warn(`keypoints: 400 bad page ${page?.url}`), res.writeHead(400).end('bad page');
      page.at = new Date().toISOString();
      appendFileSync(PAGES, JSON.stringify(page) + '\n', { mode: 0o600 });
      res.writeHead(204).end();
    });
  }).listen(PORT, '127.0.0.1', () => console.log(`keypoints: collecting into ${PAGES} on 127.0.0.1:${PORT}`));
}

async function ask(sentences: string[]): Promise<number[]> {
  const max = Math.max(1, Math.ceil(sentences.length * RATIO));
  const r = await fetch(`${OLLAMA}/api/chat`, {
    method: 'POST',
    body: JSON.stringify({
      model: TEACHER, stream: false, think: false, keep_alive: '5m', options: { temperature: 0, num_ctx: 8192 },
      format: { type: 'object', properties: { indices: { type: 'array', items: { type: 'integer' } } }, required: ['indices'] },
      messages: [
        { role: 'system', content: `${SYSTEM} Pick at most ${max}.` },
        { role: 'user', content: sentences.map((s, i) => `[${i}] ${s}`).join('\n') },
      ],
    }),
  });
  if (!r.ok) throw new Error(`Ollama ${r.status}: ${(await r.text()).slice(0, 200)}`);
  const picks: number[] = JSON.parse((await r.json()).message.content).indices;
  return [...new Set(picks.filter((i) => Number.isInteger(i) && i >= 0 && i < sentences.length))].slice(0, max);
}

const notify = (msg: string) => {
  console.log(msg);
  try {
    execFileSync('notify-send', ['-a', 'keypoints', 'Keypoints', msg]);
  } catch {} // no notification daemon (e.g. ssh): the log line is enough
};

function gpuBusy(): boolean {
  try {
    return Number(execFileSync('nvidia-smi', ['--query-gpu=utilization.gpu', '--format=csv,noheader,nounits'], { encoding: 'utf8' }).split('\n')[0]) > 30;
  } catch {
    return false;
  }
}

async function label() {
  if (process.argv.includes('--if-idle') && gpuBusy()) return console.log('keypoints: GPU busy, skipping this run');
  const size = (p: Page) => p.chunks.reduce((n, c) => n + c.sentences.length, 0);
  const done = new Map(readJsonl<Page>(LABELS).map((p) => [p.url, size(p)]));
  // Latest capture per URL wins; relabelled only once it grew by half (lazy-loaded reviews, comments).
  const todo = [...new Map(readJsonl<Page>(PAGES).map((p) => [p.url, p])).values()].filter((p) => !done.has(p.url) || size(p) >= done.get(p.url)! * 1.5);
  if (!todo.length) return console.log('keypoints: nothing new to label');
  let ok = 0;
  try {
    const t0 = Date.now();
    for (const page of todo) {
      if (Date.now() - t0 > BUDGET_MS) break;
      const chunks = [];
      for (const c of page.chunks) chunks.push({ sentences: c.sentences, picks: await ask(c.sentences) });
      appendFileSync(LABELS, JSON.stringify({ ...page, model: TEACHER, at: new Date().toISOString(), chunks }) + '\n', { mode: 0o600 });
      ok++;
    }
  } catch (e) {
    notify(`labelled ${ok}/${todo.length} pages, then failed: ${(e as Error).message}`);
    process.exitCode = 1;
  } finally {
    // Free the teacher's VRAM right away instead of after keep_alive.
    await fetch(`${OLLAMA}/api/generate`, { method: 'POST', body: JSON.stringify({ model: TEACHER, keep_alive: 0 }) }).catch(() => {});
  }
  if (!process.exitCode) notify(`labelled ${ok} new pages (${done.size + ok} total) with ${TEACHER}${ok < todo.length ? `, ${todo.length - ok} left for next run` : ''}`);
}

function stats() {
  const pages = readJsonl<Page>(PAGES), labels = readJsonl<Page>(LABELS);
  const sentences = labels.reduce((n, p) => n + p.chunks.reduce((m, c) => m + c.sentences.length, 0), 0);
  const langs = Object.entries(Object.groupBy(labels, (p) => p.lang.split('-')[0] || '?')).map(([k, v]) => `${k}:${v!.length}`);
  console.log(`captures ${pages.length} (${new Set(pages.map((p) => p.url)).size} urls), labelled ${labels.length} pages / ${sentences} sentences, langs ${langs.join(' ') || '-'}`);
}

if (import.meta.main) {
  const cmd = process.argv[2];
  if (cmd === 'serve') serve();
  else if (cmd === 'label') await label();
  else if (cmd === 'stats') stats();
  else console.error('usage: keypoints serve | label [--if-idle] | stats'), (process.exitCode = 2);
}
