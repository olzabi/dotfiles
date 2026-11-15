import type { EngineInterface } from 'claude-code';

const REFOCUS_MS = 150;

// One press opens the pane, the next closes it. A pane still waiting for room counts as open, so a second
// press also cancels the wait. Resolves whether the pane is open after the press.
// The open asks for the keys (and esc to close); the surface grants them only while the prompt holds them, which
// a press in the footer may not leave it doing at once, so an open that did not get them asks once more right after.
export async function togglePane($: EngineInterface, id: string, title: string): Promise<boolean> {
  if ((await $.ui.panes()).some((p) => p.id === id)) {
    await $.ui.close({ id });
    return false;
  }
  const args = { id, title, focus: true, closeOnEscape: true } as const;
  const r = await $.ui.open(args);
  if (!r.isPlaced) {
    $.ui.toast(`${title} waits for room (${r.reason}); press again to cancel`);
    return true;
  }
  const pane = (await $.ui.panes()).find((p) => p.id === id);
  if (pane && !pane.isFocused) $.clock.after(REFOCUS_MS, () => void $.ui.open(args));
  return true;
}
