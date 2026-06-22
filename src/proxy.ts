import NextAuth from "next-auth";
import { authConfig } from "@/auth.config";

// Next.js 16 proxy (formerly middleware). Edge-only, JWT check — no DB/bcrypt.
const { auth: withAuth } = NextAuth(authConfig);

export default withAuth((req) => {
  // The `authorized` callback in authConfig handles allow/redirect logic.
  void req;
});

export const config = {
  matcher: [
    // Exclude static assets, Next internals, auth routes, and the two
    // Google endpoints that receive requests without a user session:
    //   - /api/google/callback  (redirect from Google after OAuth)
    //   - /api/google/webhook   (push notifications from Google's servers)
    "/((?!api/auth|api/google/callback|api/google/webhook|_next/static|_next/image|favicon.ico).*)",
  ],
};
