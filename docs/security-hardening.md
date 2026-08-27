# Security Hardening

This app is deployed publicly but is intended for a single owner account.

## Required production environment

Set these in Vercel production:

```text
APP_OWNER_EMAIL=luca.ilchen@gmail.com
APP_ALLOWED_EMAILS=luca.ilchen@gmail.com
APP_SIGNUP_TOKEN=
APP_ENCRYPTION_KEY=<openssl rand -base64 32>
AUTH_SECRET=<npx auth secret>
APP_URL=https://your-app.vercel.app
```

`APP_SIGNUP_TOKEN` should normally be empty. To create an allowed account, set a
strong temporary value, sign up with that invite code, then remove the variable.

## Vercel Firewall

The code now adds app-level throttles, but Vercel Firewall is the stronger layer
against internet bot traffic. Recommended production rules:

- Enable Managed Rulesets: OWASP, Bot Protection, AI Bots. Use `challenge` first,
  then switch obvious abuse to `deny`.
- Rate limit `POST /api/auth/callback/credentials`: 10 requests per 10 minutes per
  IP, action `challenge` or `deny`.
- Rate limit `POST /api/v1/auth/session`: 10 requests per 10 minutes per IP,
  action `deny`. This is the native credentials exchange.
- Rate limit `POST /api/signup`: 5 requests per hour per IP, action `deny`.
- Deny common scanner paths: `/wp-admin`, `/wp-login.php`, `/.env`,
  `/xmlrpc.php`, `/phpmyadmin`, `/admin`, `/cgi-bin`.
- Log first, then deny, if you add broad country or ASN blocking.

## Webhooks

- Set `GOOGLE_WEBHOOK_TOKEN` and reconnect Google Calendar so new watch channels
  include the shared token.
- Set `GOOGLE_HEALTH_WEBHOOK_TOKEN` and configure the Google Health webhook URL
  with `?token=<value>` unless the provider supports an authorization header.
