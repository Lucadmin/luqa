# Luqa

Luqa is becoming a Flutter-first personal operating system while the existing
Next.js application remains the supported web companion and Vercel API host.

- `mobile/` contains the Android-first Flutter application.
- `src/` contains the existing web UI and server routes.
- `prisma/` contains the shared Neon-backed data model.
- `docs/flutter-migration-plan.md` records the staged migration.

## Flutter application

The first mobile vertical slice includes the adaptive five-destination shell,
light and dark design system, Today timeline, retrospective Log time sheet,
recent-activity shortcuts, category search/creation, and an in-memory repository.

```bash
npm run mobile:analyze
npm run mobile:test
npm run mobile:build:android
```

See [mobile/README.md](mobile/README.md) for setup and architecture details.

## Web companion

This public deployment is locked to the configured owner email. Before deploying
to Vercel, review [docs/security-hardening.md](docs/security-hardening.md) and
set the security environment variables from `.env.example`.

```bash
npm install
npm run dev
```

Open [http://localhost:3000](http://localhost:3000). The web application
continues to deploy through Vercel. Mobile API work will add a versioned
`/api/v1` contract without removing the browser interface.
