// Money helpers. Everything in the shared-expense feature is integer cents —
// a bill is only ever divided by `allocate` in split.ts, never by floats — so
// these functions are the single place where cents meet the screen.

const DEFAULT_CURRENCY = "EUR";

// Formatting is pinned to one locale on purpose: the money screens are client
// components that also render on the server, and a locale that differs between
// the two would produce a hydration mismatch on every amount.
const LOCALE = "en-US";

const formatters = new Map<string, Intl.NumberFormat>();

function formatterFor(currency: string, fractionDigits: number) {
  const key = `${currency}:${fractionDigits}`;
  let f = formatters.get(key);
  if (!f) {
    f = new Intl.NumberFormat(LOCALE, {
      style: "currency",
      currency,
      minimumFractionDigits: fractionDigits,
      maximumFractionDigits: fractionDigits,
    });
    formatters.set(key, f);
  }
  return f;
}

/**
 * "€12.50". Pass `signed` for ledger rows that need an explicit + or −, and
 * `compact` to drop ".00" on whole amounts (kinder on dense lists).
 */
export function formatMoney(
  cents: number,
  currency: string = DEFAULT_CURRENCY,
  opts: { signed?: boolean; compact?: boolean } = {},
): string {
  const rounded = Math.round(cents);
  const whole = rounded % 100 === 0;
  const digits = opts.compact && whole ? 0 : 2;
  const text = formatterFor(currency, digits).format(Math.abs(rounded) / 100);

  if (rounded < 0) return `−${text}`;
  if (opts.signed && rounded > 0) return `+${text}`;
  return text;
}

/** Just the symbol, for prefixing an input field. */
export function currencySymbol(currency: string = DEFAULT_CURRENCY): string {
  const parts = formatterFor(currency, 2).formatToParts(0);
  return parts.find((p) => p.type === "currency")?.value ?? currency;
}

/**
 * Parse whatever someone types into an amount field. Accepts "12", "12.5",
 * "12,50", "1.234,50", "1,234.50" and a leading symbol. Returns null when the
 * text isn't a number, so callers can leave the field alone while it's a
 * half-finished "12,".
 */
export function parseAmountToCents(input: string): number | null {
  const cleaned = input.replace(/[^\d.,-]/g, "").trim();
  if (!cleaned || cleaned === "-") return null;

  const lastDot = cleaned.lastIndexOf(".");
  const lastComma = cleaned.lastIndexOf(",");
  const decimalAt = Math.max(lastDot, lastComma);

  let normalized: string;
  if (decimalAt === -1) {
    normalized = cleaned;
  } else {
    // The rightmost separator is the decimal point only if it splits off 1–2
    // digits; "1.234" is a thousands separator, "1.23" is euros and cents.
    const tail = cleaned.slice(decimalAt + 1);
    if (/^\d{1,2}$/.test(tail)) {
      normalized = `${cleaned.slice(0, decimalAt).replace(/[.,]/g, "")}.${tail}`;
    } else {
      normalized = cleaned.replace(/[.,]/g, "");
    }
  }

  const value = Number(normalized);
  if (!Number.isFinite(value)) return null;
  return Math.round(value * 100);
}

/** Swatches for person and group avatars. */
export const PERSON_PALETTE = [
  "#6366f1", // indigo
  "#ec4899", // pink
  "#f97316", // orange
  "#10b981", // emerald
  "#0ea5e9", // sky
  "#eab308", // yellow
  "#8b5cf6", // violet
  "#ef4444", // red
  "#14b8a6", // teal
  "#a855f7", // purple
] as const;

/** Percent basis points (10000 = 100%) → "33.33%", trimming dead zeros. */
export function formatPercent(bp: number): string {
  const pct = bp / 100;
  const text = Number.isInteger(pct) ? String(pct) : pct.toFixed(2).replace(/0+$/, "");
  return `${text}%`;
}

/** "40" / "33.5" → basis points, or null if it isn't a number. */
export function parsePercentToBp(input: string): number | null {
  const value = Number(input.replace(/[^\d.,-]/g, "").replace(",", "."));
  if (!Number.isFinite(value)) return null;
  return Math.round(value * 100);
}
