// ==UserScript==
// @name        Keypoints
// @namespace   dotfiles
// @version     0.8
// @downloadURL http://127.0.0.1:11500/keypoints.user.js
// @description Highlight the key sentences of a page with a local Ollama model (Ctrl+Alt+K or F2 toggles).
// @match       *://*/*
// @grant       GM_xmlhttpRequest
// @grant       GM_registerMenuCommand
// @grant       GM_addStyle
// @grant       GM_info
// @inject-into page
// @connect     127.0.0.1
// @run-at      document-idle
// @noframes
// ==/UserScript==

// Ollama rejects extension origins by default: `sudo systemctl edit ollama`, add
// [Service] Environment="OLLAMA_ORIGINS=moz-extension://*", then `sudo systemctl restart ollama`.
const OLLAMA = 'http://127.0.0.1:11434/api/chat';
const COLLECTOR = 'http://127.0.0.1:11500/pages'; // `keypoints serve`
const MODEL = 'qwen2.5:3b'; // ~2.4 GB VRAM; qwen2.5:7b (~5 GB) picks better
const CHUNK_CHARS = 4000; // ~1k tokens per request, so picks spread over the page
const RATIO = 0.2; // max share of sentences marked per chunk
const SYSTEM =
  'You mark key sentences for a speed reader. Given numbered sentences, return the indices of the few ' +
  'sentences that carry the main points: core claims, conclusions, definitions, decisions, key numbers. ' +
  'Skip examples, filler, transitions and repetition. If the text is several posts by different people ' +
  "(reviews, comments, answers), pick each substantial post's verdict or strongest reason."; // same as keypoints.ts

// Map a char offset in the concatenated text of nodes (starts[i] = offset of node i) to [node index, offset].
function locate(starts, pos) {
  let i = starts.length - 1;
  while (i > 0 && starts[i] > pos) i--;
  return [i, pos - starts[i]];
}

// Group sentences into chunks of at most `max` chars (a single long sentence is its own chunk).
function chunk(sentences, max) {
  const out = [];
  let cur = [], size = 0;
  for (const s of sentences) {
    if (cur.length && size + s.text.length > max) out.push(cur), (cur = []), (size = 0);
    cur.push(s);
    size += s.text.length;
  }
  if (cur.length) out.push(cur);
  return out;
}

if (typeof document === 'undefined') {
  // Self-check: `node keypoints.user.js`
  const assert = require('node:assert');
  assert.deepStrictEqual(locate([0, 5, 12], 0), [0, 0]);
  assert.deepStrictEqual(locate([0, 5, 12], 5), [1, 0]);
  assert.deepStrictEqual(locate([0, 5, 12], 11), [1, 6]);
  assert.deepStrictEqual(locate([0, 5, 12], 20), [2, 8]);
  const s = (n) => ({ text: 'x'.repeat(n) });
  assert.deepStrictEqual(chunk([s(3), s(3), s(5), s(9)], 6).map((c) => c.length), [2, 1, 1]);
  console.log('ok');
} else {
  const highlight = new Highlight();
  CSS.highlights.set('keypoint', highlight);
  GM_addStyle('::highlight(keypoint){background:rgba(255,200,0,.3);color:inherit}'); // survives page CSP, unlike a <style> tag
  let running = false;

  const SKIP = 'nav, aside, header, footer, [role=navigation], script, style, noscript, button, select, textarea, pre, code, [contenteditable]';
  const shown = new WeakMap();
  const blockOf = (el) => {
    while (el.parentElement && getComputedStyle(el).display.startsWith('inline')) el = el.parentElement;
    return el;
  };

  // Text grouped by its nearest block box, so reviews/comments in <div><span>…<br>… count, not only <p>.
  const blocks = () => {
    const root = document.querySelector('main, [role=main]') || (document.querySelectorAll('article').length === 1 && document.querySelector('article')) || document.body;
    const groups = new Map();
    const walker = document.createTreeWalker(root, NodeFilter.SHOW_TEXT, {
      acceptNode: (n) => (n.data.trim() && !n.parentElement.closest(SKIP) ? NodeFilter.FILTER_ACCEPT : NodeFilter.FILTER_REJECT),
    });
    for (let n; (n = walker.nextNode()); ) {
      const b = blockOf(n.parentElement);
      if (!shown.has(b)) shown.set(b, b.checkVisibility());
      if (shown.get(b)) groups.has(b) ? groups.get(b).push(n) : groups.set(b, [n]);
    }
    return [...groups.values()].filter((ns) => ns.reduce((k, n) => k + n.data.length, 0) >= 80);
  };

  const sentencesOf = (nodes) => {
    const starts = [];
    let text = '';
    for (const n of nodes) starts.push(text.length), (text += n.data);
    const out = [];
    for (const { segment, index } of new Intl.Segmenter(document.documentElement.lang || undefined, { granularity: 'sentence' }).segment(text)) {
      const t = segment.trim();
      if (t.length < 25) continue;
      const from = index + segment.indexOf(t);
      const [a, ao] = locate(starts, from), [b, bo] = locate(starts, from + t.length);
      const range = new Range();
      range.setStart(nodes[a], ao);
      range.setEnd(nodes[b], bo);
      out.push({ text: t.replace(/\s+/g, ' '), range });
    }
    return out;
  };

  const pageChunks = () => chunk(blocks().flatMap(sentencesOf), CHUNK_CHARS).filter((g) => g.length > 2); // too little context below 3
  const pageInfo = () => ({ url: location.href.split('#')[0], title: document.title, lang: document.documentElement.lang || '' });

  const ask = (sentences) =>
    new Promise((resolve, reject) =>
      GM_xmlhttpRequest({
        method: 'POST',
        url: OLLAMA,
        headers: { 'Content-Type': 'application/json' },
        data: JSON.stringify({
          model: MODEL,
          stream: false,
          think: false,
          keep_alive: '10m',
          options: { temperature: 0, num_ctx: 8192 },
          format: { type: 'object', properties: { indices: { type: 'array', items: { type: 'integer' } } }, required: ['indices'] },
          messages: [
            { role: 'system', content: `${SYSTEM} Pick at most ${Math.max(1, Math.ceil(sentences.length * RATIO))}.` },
            { role: 'user', content: sentences.map((s, i) => `[${i}] ${s.text}`).join('\n') },
          ],
        }),
        onload: (r) => {
          if (r.status !== 200) return reject(new Error(`Ollama ${r.status}: ${r.responseText.slice(0, 200)}`));
          resolve(JSON.parse(JSON.parse(r.responseText).message.content).indices);
        },
        onerror: () => reject(new Error('Ollama unreachable at ' + OLLAMA)),
      }),
    );

  // Training data for a future in-browser model (config/firefox/keypoints); silent if the collector is off.
  const collect = (page) =>
    GM_xmlhttpRequest({
      method: 'POST',
      url: COLLECTOR,
      headers: { 'Content-Type': 'application/json', 'X-Keypoints': '1' },
      data: JSON.stringify(page),
      onload: (r) => r.status !== 204 && console.warn('[keypoints] collector', r.status, r.responseText),
      onerror: () => console.warn('[keypoints] collector unreachable at ' + COLLECTOR),
    });

  const run = async () => {
    if (highlight.size) return highlight.clear();
    if (running) return;
    running = true;
    try {
      const chunks = [];
      for (const group of pageChunks()) {
        // Cap in code too: some models (qwen3.5) ignore the limit and return every index.
        const picks = [...new Set((await ask(group)).filter((i) => group[i]))].slice(0, Math.max(1, Math.ceil(group.length * RATIO)));
        for (const i of picks) highlight.add(group[i].range);
        chunks.push({ sentences: group.map((s) => s.text), picks });
      }
      console.info(`[keypoints] v${GM_info.script.version}: ${highlight.size} sentences highlighted`);
      if (chunks.length) collect({ ...pageInfo(), model: MODEL, chunks });
    } catch (e) {
      console.error('[keypoints]', e);
      alert('Keypoints: ' + e.message);
    } finally {
      running = false;
    }
  };

  // Auto-capture text (no model call) for the teacher to label later. Everything except private windows.
  // A page counts as read after ~1s visible per 150 chars of text, 3..30s; rechecked every 30s so lazy
  // content (more reviews, infinite scroll) is captured again once it grows by half.
  let url = '', visibleMs = 0, sent = 0, lastCheck = 0, tick = Date.now();
  const capture = () => {
    const chunks = pageChunks(), n = chunks.reduce((k, g) => k + g.length, 0);
    if (n < 3 || n < sent * 1.5) return;
    sent = n;
    collect({ ...pageInfo(), model: 'none', chunks: chunks.map((g) => ({ sentences: g.map((s) => s.text), picks: [] })) });
  };
  setInterval(() => {
    const now = Date.now(), dt = now - tick;
    tick = now;
    if (GM_info.isIncognito) return;
    const u = pageInfo().url;
    if (u !== url) (url = u), (visibleMs = 0), (sent = 0), (lastCheck = 0);
    if (document.hidden) return;
    visibleMs += dt;
    const need = Math.min(30, Math.max(3, document.body.textContent.length / 150)) * 1000;
    if (visibleMs >= need && now - lastCheck >= 30_000) (lastCheck = now), capture();
  }, 1000);
  // Switching away early still counts a short read.
  addEventListener('visibilitychange', () => document.hidden && !sent && visibleMs >= 3000 && !GM_info.isIncognito && capture());

  GM_registerMenuCommand('Toggle keypoints (Ctrl+Alt+K / F2)', run);
  // Ctrl+Alt+K or F2: free in Firefox, Vimium-C and niri (Super-based); Alt+letter opens menus, Alt+Shift is
  // Firefox's accesskey chord, F1/3/5/6/7/10/11/12 are taken. Capture phase so sites can't swallow it; skipped while typing.
  addEventListener(
    'keydown',
    (e) => {
      const mods = e.ctrlKey || e.altKey || e.metaKey || e.shiftKey;
      if (!(e.ctrlKey && e.altKey && !e.metaKey && !e.shiftKey && e.code === 'KeyK') && !(!mods && e.code === 'F2')) return;
      if (e.target.closest?.('input, textarea, select, [contenteditable]:not([contenteditable=false])')) return;
      e.preventDefault(), e.stopPropagation(), run();
    },
    true,
  );
}
