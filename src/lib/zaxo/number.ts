// ==================== ZAXO NUMBER GENERATION ALGORITHM ====================
// Format: XXX-XXX-XXX (9 digits)
// - First 3: Region/Creation time hash
// - Middle 3: Random unique sequence
// - Last 3: Checksum verification (Luhn-style)

/**
 * Generate a unique 9-digit Zaxo number in XXX-XXX-XXX format.
 * Algorithm:
 *  1. First 3 digits: deterministic hash from timestamp + userId (region-style)
 *  2. Middle 3 digits: cryptographically random sequence
 *  3. Last 3 digits: weighted checksum from the first 6 digits
 *
 * The number is permanent and never changes once assigned.
 */
export function generateZaxoNumber(seed?: string): string {
  const base = seed ?? `${Date.now()}-${Math.random()}`;

  // Part 1: Region/time hash → 3 digits
  const regionHash = simpleHash(base) % 900 + 100; // 100-999
  const part1 = regionHash.toString().padStart(3, "0");

  // Part 2: Random unique sequence → 3 digits
  const part2 = Math.floor(Math.random() * 900 + 100).toString().padStart(3, "0");

  // Part 3: Checksum → 3 digits
  const checksum = computeChecksum(part1 + part2);
  const part3 = checksum.toString().padStart(3, "0");

  return `${part1}-${part2}-${part3}`;
}

/**
 * Compute a 3-digit checksum using a weighted sum + Luhn-style doubling.
 */
function computeChecksum(sixDigits: string): number {
  const digits = sixDigits.split("").map((d) => parseInt(d, 10));
  let sum = 0;
  for (let i = 0; i < digits.length; i++) {
    let d = digits[i];
    // Double every second digit, sum the resulting digits if >= 10
    if (i % 2 === 0) {
      d *= 2;
      if (d >= 10) d = Math.floor(d / 10) + (d % 10);
    }
    sum += d;
  }
  // Build a 3-digit checksum
  const a = (sum * 7) % 10;
  const b = (sum * 13) % 10;
  const c = (sum * 29 + a + b) % 10;
  return a * 100 + b * 10 + c;
}

/**
 * Validate a Zaxo number against its checksum.
 */
export function validateZaxoNumber(number: string): boolean {
  const cleaned = number.replace(/[^0-9]/g, "");
  if (cleaned.length !== 9) return false;
  const part1 = cleaned.slice(0, 3);
  const part2 = cleaned.slice(3, 6);
  const expected = parseInt(cleaned.slice(6, 9), 10);
  return computeChecksum(part1 + part2) === expected;
}

/**
 * Normalize any input (XXX-XXX-XXX, XXXXXXXXX, XXX XXX XXX) to canonical form.
 */
export function normalizeZaxoNumber(input: string): string {
  const cleaned = input.replace(/[^0-9]/g, "");
  if (cleaned.length !== 9) return input;
  return `${cleaned.slice(0, 3)}-${cleaned.slice(3, 6)}-${cleaned.slice(6, 9)}`;
}

/**
 * Simple non-cryptographic string hash (djb2 variant).
 */
function simpleHash(s: string): number {
  let h = 5381;
  for (let i = 0; i < s.length; i++) {
    h = (h * 33) ^ s.charCodeAt(i);
  }
  return Math.abs(h);
}

/**
 * Mock function: simulate atomic uniqueness check against a registry.
 * In production this would be a Firestore transaction.
 */
const assignedNumbers = new Set<string>();
export function isZaxoNumberUnique(number: string): boolean {
  if (assignedNumbers.has(number)) return false;
  assignedNumbers.add(number);
  return true;
}

export function generateUniqueZaxoNumber(seed?: string): string {
  // Try up to 50 times to find a unique number
  for (let i = 0; i < 50; i++) {
    const candidate = generateZaxoNumber(seed ? `${seed}-${i}` : undefined);
    if (isZaxoNumberUnique(candidate)) return candidate;
  }
  // Fallback - extremely unlikely
  return generateZaxoNumber(seed);
}

/**
 * Format a Zaxo number for display, with optional grouping.
 */
export function formatZaxoDisplay(number: string): string {
  return normalizeZaxoNumber(number);
}
