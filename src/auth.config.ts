import type { NextAuthConfig } from "next-auth";
import { isAllowedEmail } from "@/lib/security-config";

// Edge-safe config shared by middleware and the full server-side auth.
// No database, bcrypt, or `ws` imports here — middleware runs on the edge.
export const authConfig = {
  session: {
    strategy: "jwt",
    maxAge: 7 * 24 * 60 * 60,
    updateAge: 24 * 60 * 60,
  },
  pages: {
    signIn: "/login",
  },
  providers: [], // real providers are added in auth.ts
  callbacks: {
    authorized({ auth, request: { nextUrl } }) {
      const isLoggedIn = !!auth?.user;
      const isAllowedUser = isAllowedEmail(auth?.user?.email);
      const isAuthPage =
        nextUrl.pathname.startsWith("/login") ||
        nextUrl.pathname.startsWith("/signup");
      const isPublicApi =
        nextUrl.pathname.startsWith("/api/auth") ||
        // Native API routes enforce their own opaque bearer-token sessions.
        nextUrl.pathname.startsWith("/api/v1/") ||
        nextUrl.pathname === "/api/signup" ||
        nextUrl.pathname === "/api/google/callback" ||
        nextUrl.pathname === "/api/google/webhook" ||
        nextUrl.pathname === "/api/health/google/callback" ||
        nextUrl.pathname === "/api/health/google/webhook";

      // Logged-in users should not sit on auth pages.
      if (isAuthPage) {
        if (isLoggedIn && isAllowedUser) {
          return Response.redirect(new URL("/", nextUrl));
        }
        return true;
      }

      if (isPublicApi) return true;

      // Everything else requires a session.
      return isLoggedIn && isAllowedUser;
    },
    jwt({ token, user }) {
      if (user) token.id = user.id;
      return token;
    },
    session({ session, token }) {
      if (token.id) session.user.id = token.id as string;
      return session;
    },
  },
} satisfies NextAuthConfig;
