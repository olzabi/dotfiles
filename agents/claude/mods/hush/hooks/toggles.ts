import type { Toggle, Toggles } from '../types'

// The state scan reads an atom only where its file declares it, so each file that reads
// a value declares its own atom with this same initial value.
export const TOGGLES_INITIAL: Toggles = { prompt: true, thinking: true }

// Previews start off (a call folds to its row), and the spinner line is hidden. Every other tweak starts on.
const DEFAULT_OFF: Toggle[] = ['previews', 'spinner', 'tight']
export const isOn = (t: Toggles, k: Toggle) => t[k] ?? !DEFAULT_OFF.includes(k)
