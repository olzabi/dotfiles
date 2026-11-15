import type { ModelUsage } from 'claude-code';

import type { CacheStep, Limit, Repo } from '../types';

// `five_hour` → `5h`, `seven_day` → `7d`, a gateway's `spend_limit` → `spend`; anything else as given.
export function limitLabel(kind: string): string {
  return ({ five_hour: '5h', seven_day: '7d', spend_limit: 'spend' } as Record<string, string>)[kind] ?? kind;
}

// Time left until an ISO reset: `35m`, `1h42m`, `2d`; undefined when absent, unreadable or past.
export function until(resetsAt: string | undefined, now: number): string | undefined {
  const at = resetsAt ? Date.parse(resetsAt) : NaN;
  if (!Number.isFinite(at) || at <= now) return undefined;
  const m = Math.round((at - now) / 60_000);
  if (m < 60) return `${m}m`;
  if (m < 48 * 60) return `${Math.floor(m / 60)}h${String(m % 60).padStart(2, '0')}m`;
  return `${Math.round(m / 1440)}d`;
}

// The windows in a stable order (5h, 7d, then the rest), only those with a reading.
export function orderLimits(limits: readonly Limit[]): Limit[] {
  const rank = (k: string) => (k === 'five_hour' ? 0 : k === 'seven_day' ? 1 : 2);
  return [...limits].sort((a, b) => rank(a.kind) - rank(b.kind));
}

// `▰▰▰▱▱▱▱▱` for a share from 0 to 1, clamped.
export function meter(share: number, cells = 8): string {
  const on = Math.max(0, Math.min(cells, Math.round(share * cells)));
  return '▰'.repeat(on) + '▱'.repeat(cells - on);
}

// One request's prompt as the cache saw it; undefined when it sent no input at all.
export function cacheStep(u: ModelUsage, at: number): CacheStep | undefined {
  const step = { read: u.cache_read_input_tokens, written: u.cache_creation_input_tokens, fresh: u.input_tokens, at };
  return step.read + step.written + step.fresh > 0 ? step : undefined;
}

export const hitOf = (s: CacheStep) => Math.round((s.read / (s.read + s.written + s.fresh)) * 100);

// `▁▃▇█` for shares from 0 to 100, one cell each: the cache's recent history at a glance.
export const spark = (values: readonly number[]) =>
  values.map((v) => '▁▂▃▄▅▆▇█'[Math.max(0, Math.min(7, Math.floor((v / 100) * 8)))]).join('');

// `14s`, `3m`, `1h5m` since a moment, for figures that age.
export function ago(at: number, now: number): string {
  const s = Math.max(0, Math.round((now - at) / 1000));
  if (s < 60) return `${s}s`;
  if (s < 3600) return `${Math.floor(s / 60)}m`;
  return `${Math.floor(s / 3600)}h${Math.floor((s % 3600) / 60)}m`;
}

// `$3.42`, `$0.07`, `$12`.
export const usd = (n: number) => (n >= 10 ? `$${Math.round(n)}` : `$${n.toFixed(2)}`);

// `rev-parse --path-format=absolute --show-toplevel --git-dir --git-common-dir` with `branch --show-current`, read:
// a linked worktree has its own git dir, apart from the common one; a detached HEAD has no branch.
export function parseRevParse(stdout: string, current?: string): Pick<Repo, 'branch' | 'worktree'> | null {
  const [top, gitDir, common] = stdout
    .trim()
    .split('\n')
    .map((s) => s.trim());
  if (!top || !gitDir || !common) return null;
  const branch = current?.trim() || null;
  const name = top.split('/').filter(Boolean).pop();
  const worktree = gitDir !== common && name && name !== branch ? name : undefined;
  return { branch, worktree };
}

// `git status --porcelain`: one changed or untracked path per line.
export const countDirty = (stdout: string) => stdout.split('\n').filter((l) => l.trim()).length;
