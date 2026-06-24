import {
  createCipheriv,
  createDecipheriv,
  createHash,
  randomBytes,
} from "crypto";

const PREFIX = "enc:v1:";

function keyFromEnv(): Buffer | null {
  const configured = process.env.APP_ENCRYPTION_KEY?.trim();

  if (configured) {
    if (/^[0-9a-f]{64}$/i.test(configured)) {
      return Buffer.from(configured, "hex");
    }

    const base64 = Buffer.from(configured, "base64");
    if (base64.length === 32) return base64;

    return createHash("sha256").update(configured).digest();
  }

  const authSecret = process.env.AUTH_SECRET?.trim();
  if (!authSecret) return null;

  return createHash("sha256").update(authSecret).digest();
}

export function encryptSecret(value: string): string {
  if (!value || value.startsWith(PREFIX)) return value;

  const key = keyFromEnv();
  if (!key) return value;

  const iv = randomBytes(12);
  const cipher = createCipheriv("aes-256-gcm", key, iv);
  const ciphertext = Buffer.concat([
    cipher.update(value, "utf8"),
    cipher.final(),
  ]);
  const tag = cipher.getAuthTag();

  return `${PREFIX}${Buffer.concat([iv, tag, ciphertext]).toString("base64url")}`;
}

export function decryptSecret(value: string): string {
  if (!value.startsWith(PREFIX)) return value;

  const key = keyFromEnv();
  if (!key) {
    throw new Error("APP_ENCRYPTION_KEY or AUTH_SECRET is required to decrypt secrets");
  }

  const payload = Buffer.from(value.slice(PREFIX.length), "base64url");
  if (payload.length <= 28) {
    throw new Error("Stored secret payload is invalid");
  }

  const iv = payload.subarray(0, 12);
  const tag = payload.subarray(12, 28);
  const ciphertext = payload.subarray(28);
  const decipher = createDecipheriv("aes-256-gcm", key, iv);
  decipher.setAuthTag(tag);

  return Buffer.concat([
    decipher.update(ciphertext),
    decipher.final(),
  ]).toString("utf8");
}
