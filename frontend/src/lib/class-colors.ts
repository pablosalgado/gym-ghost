/**
 * Derive a deterministic pastel color from a class name.
 *
 * Uses the Java-style string hash (lossy, stable, no crypto needed)
 * to pick a hue, then outputs an HSLA string with muted saturation
 * and high lightness so the result is always legible on white.
 *
 * The color is *always* pastel — saturation and lightness are fixed
 * at 50% / 85%, with 40% alpha so the tint is subtle.
 */

const HUE_RANGE = 360
const SATURATION = 50
const LIGHTNESS = 85
const ALPHA = 0.4

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
 * Map any string to a pastel HSLA color.
 * @returns CSS HSLA function string, e.g. `"hsla(42, 50%, 85%, 0.4)"`
 */
export function classNameToColor(name: string): string {
  const hue = ((hashCode(name) % HUE_RANGE) + HUE_RANGE) % HUE_RANGE
  return `hsla(${hue}, ${SATURATION}%, ${LIGHTNESS}%, ${ALPHA})`
}
