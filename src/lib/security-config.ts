const DEFAULT_OWNER_EMAIL = "luca.ilchen@gmail.com";

export function normalizeEmail(email: string): string {
  return email.trim().toLowerCase();
}

export function allowedEmails(): string[] {
  const configured =
    process.env.APP_ALLOWED_EMAILS?.trim() ||
    process.env.APP_OWNER_EMAIL?.trim() ||
    DEFAULT_OWNER_EMAIL;

  return configured
    .split(",")
    .map((email) => normalizeEmail(email))
    .filter(Boolean);
}

export function isAllowedEmail(email: string | null | undefined): boolean {
  if (!email) return false;
  return allowedEmails().includes(normalizeEmail(email));
}

export function configuredSignupToken(): string | null {
  return process.env.APP_SIGNUP_TOKEN?.trim() || null;
}

export function isSignupEnabled(): boolean {
  return process.env.NODE_ENV !== "production" || Boolean(configuredSignupToken());
}

export function signupRequiresToken(): boolean {
  return Boolean(configuredSignupToken());
}
