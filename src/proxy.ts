import NextAuth from "next-auth";
import { authConfig } from "@/auth.config";

// Next.js 16 proxy (formerly middleware). Edge-only, JWT check — no DB/bcrypt.
const { auth: withAuth } = NextAuth(authConfig);

export default withAuth((req) => {
  // The `authorized` callback in authConfig handles allow/redirect logic.
  void req;
});

export const config = {
  // Run on everything except static assets and Next internals.
  matcher: ["/((?!api/auth|_next/static|_next/image|favicon.ico).*)"],
};
