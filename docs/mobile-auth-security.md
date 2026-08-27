# Mobile authentication security

Status: implemented contract v1

## Boundary

The browser keeps its existing Auth.js credentials session. Flutter uses a
separate native device-session exchange under `/api/v1/auth`; Auth.js cookies
are never copied into the app and mobile bearer tokens are never accepted by
the legacy web routes.

Neon remains the authorization source. Every mobile data request resolves its
access-token hash to a non-revoked session, verifies expiry, rechecks the owner
allowlist, and derives the user ID server-side. Clients cannot select a user ID.

## Credential lifecycle

- Login accepts the existing email/password plus an installation-scoped device
  ID and optional display name.
- The server returns 256-bit random opaque access and refresh tokens.
- Access tokens expire after 15 minutes.
- Refresh tokens expire after 30 days and receive a new 30-day window when
  successfully rotated.
- A refresh atomically replaces both token hashes. Concurrent reuse of the old
  refresh token fails.
- Logging in again from the same user/device ID replaces that installation's
  prior session. Logging out marks the session revoked.
- Neon stores SHA-256 token hashes only. Because the input tokens have 256 bits
  of entropy, a database leak does not expose usable bearer credentials.

Flutter stores the refresh token and installation ID in Android Keystore / iOS
Keychain through secure storage. The access token is treated as short-lived
session state. Neither credential belongs in logs, analytics, crash metadata,
URLs, source control, or ordinary preferences/cache storage.

The generated Dart credential models redact passwords and tokens from their
string representations. `npm run api:generate` reapplies and verifies that
redaction so a generator upgrade cannot silently restore secret-bearing debug
output.

## Threats and controls

| Threat | Control | Remaining boundary |
| --- | --- | --- |
| Password guessing | Generic login error, bcrypt password verification, app-level limit, Vercel Firewall rule | Distributed attacks still require firewall/observability review |
| Database disclosure | Only hashes of high-entropy device tokens are stored | User password hashes retain the existing bcrypt policy |
| Refresh replay | Single-use atomic rotation and per-device revocation | A stolen current refresh token remains valid until rotation/expiry/revocation |
| Access-token theft | 15-minute expiry, no cookies, no URL transport, no client logs | Rooted/compromised devices are outside the first-release threat model |
| Cross-site request forgery | Native API uses explicit bearer headers rather than ambient cookies | Legacy web routes retain existing same-origin and Auth.js controls |
| Network interception | Production client requires HTTPS and Vercel terminates TLS | Certificate pinning is intentionally deferred to avoid unsafe rotation failure modes |
| User/tenant confusion | User identity comes only from the authenticated session; every query includes `userId` | Authorization tests must accompany every new resource route |

## Operational requirements

- Rate limit `POST /api/v1/auth/session` in Vercel Firewall as documented in
  `docs/security-hardening.md`; the in-process proxy bucket is defense in depth,
  not a globally consistent limiter.
- Keep `APP_ALLOWED_EMAILS` enforced. Removing an email invalidates subsequent
  access and refresh checks even before stored sessions are cleaned up.
- Never log `Authorization` headers or authentication request/response bodies.
- Add a profile security screen before multi-user launch so users can inspect
  and revoke other device sessions.
- Review expiry policy, device compromise, recovery, and abuse monitoring again
  before opening Luqa beyond its current single-owner scope.
