import type { ThemeKey } from 'claude-code';

// `6s`, `2m 6s`, `1h 4m`, as the engine's turn line writes a duration.
export function duration(ms: number): string {
  const s = Math.round(ms / 1000);
  if (s < 60) return `${s}s`;
  if (s < 3600) return `${Math.floor(s / 60)}m ${s % 60}s`;
  return `${Math.floor(s / 3600)}h ${Math.floor((s % 3600) / 60)}m`;
}

export const fit = (s: string, n: number) => (s.length > n ? `${s.slice(0, n - 1)}…` : s);

// `claude-opus-5-5` → `opus 5.5`; anything else as given.
export function shortModel(id: string): string {
  const m = /^claude-([a-z]+)-(\d+)-(\d+)/.exec(id);
  return m ? `${m[1]} ${m[2]}.${m[3]}` : id;
}

// `950`, `12.4k`, `104k`, `1.2M`.
export function tokens(n: number): string {
  if (n < 1000) return `${n}`;
  if (n < 10_000) return `${(n / 1000).toFixed(1)}k`;
  if (n < 1_000_000) return `${Math.round(n / 1000)}k`;
  return `${(n / 1_000_000).toFixed(1)}M`;
}

// shortcut: a skill body's tokens are estimated at 4 characters each; count them exactly if the engine reports it.
export const estimate = (text: string) => Math.ceil(text.length / 4);

// Coloured by how much is left before compaction runs (or before the window ends, with it off).
export function ctxColor(used: number, cap: number): ThemeKey {
  const share = cap > 0 ? used / cap : 0;
  return share >= 0.9 ? 'error' : share >= 0.7 ? 'warning' : 'subtle';
}

// Cells of a column: text padded (or cut) to a width, so rows line up.
export const cell = (s: string, n: number) => fit(s, n).padEnd(n);
