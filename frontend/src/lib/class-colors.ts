/**
 * Derive deterministic class colors from a class name.
 *
 * Uses the Java-style string hash to pick a hue, then outputs
 * two CSS HSLA strings that share the same hue:
 * - `border`: solid, clearly visible for the left accent
 * - `background`: very subtle pastel tint for the card surface
 *
 * Adding a new class type requires no code changes — the hash
 * automatically assigns a new hue.
 */

const HUE_RANGE = 360

const BORDER_SATURATION = 55
const BORDER_LIGHTNESS = 65
const BORDER_ALPHA = 1

const BG_SATURATION = 50
const BG_LIGHTNESS = 88
const BG_ALPHA = 0.35

/**
 * Deterministic hash of a string to an integer.
 * Identical to Java's `String.hashCode()` — stable across restarts.
 */
function hashCode(name: string): number {
  let hash = 0
  for (let i = 0; i < name.length; i++) {
    hash = name.charCodeAt(i) + ((hash << 5) - hash) | 0
  }
  return hash
}

/**
 * Map any string to a pair of class colors.
 * @returns `{ border, background }` with CSS HSLA function strings
 */
export function classColors(name: string): { border: string; background: string } {
  const hue = ((hashCode(name) % HUE_RANGE) + HUE_RANGE) % HUE_RANGE
  return {
    border: `hsla(${hue}, ${BORDER_SATURATION}%, ${BORDER_LIGHTNESS}%, ${BORDER_ALPHA})`,
    background: `hsla(${hue}, ${BG_SATURATION}%, ${BG_LIGHTNESS}%, ${BG_ALPHA})`,
  }
}
