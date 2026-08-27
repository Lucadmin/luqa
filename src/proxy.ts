import NextAuth from "next-auth";
import { NextResponse, type NextRequest } from "next/server";
import { authConfig } from "@/auth.config";

// Next.js 16 proxy (formerly middleware). Edge-only, JWT check — no DB/bcrypt.
const { auth: withAuth } = NextAuth(authConfig);

const MAX_API_BODY_BYTES = 5 * 1024 * 1024;
const RATE_LIMITS = {
  login: { limit: 10, windowMs: 10 * 60 * 1000 },
  mobileLogin: { limit: 10, windowMs: 10 * 60 * 1000 },
  signup: { limit: 5, windowMs: 60 * 60 * 1000 },
};

type RateLimitName = keyof typeof RATE_LIMITS;

const buckets = new Map<string, { count: number; resetAt: number }>();

function clientIp(request: NextRequest): string {
  return (
    request.headers.get("x-forwarded-for")?.split(",")[0]?.trim() ||
    request.headers.get("x-real-ip") ||
    "unknown"
  );
}

function rateLimit(
  name: RateLimitName,
  request: NextRequest,
): { limited: boolean; retryAfter: number } {
  const now = Date.now();
  const config = RATE_LIMITS[name];
  const key = `${name}:${clientIp(request)}`;
  const bucket = buckets.get(key);

  if (!bucket || bucket.resetAt <= now) {
    buckets.set(key, { count: 1, resetAt: now + config.windowMs });
    return { limited: false, retryAfter: 0 };
  }

  bucket.count += 1;
  if (bucket.count <= config.limit) {
    return { limited: false, retryAfter: 0 };
  }

  return {
    limited: true,
    retryAfter: Math.ceil((bucket.resetAt - now) / 1000),
  };
}

function isUnsafeMethod(method: string): boolean {
  return method !== "GET" && method !== "HEAD" && method !== "OPTIONS";
}

function isWebhookPath(pathname: string): boolean {
  return (
    pathname === "/api/google/webhook" ||
    pathname === "/api/health/google/webhook"
  );
}

function isSameOrigin(request: NextRequest): boolean {
  const origin = request.headers.get("origin");
  if (origin && origin !== request.nextUrl.origin) return false;

  const fetchSite = request.headers.get("sec-fetch-site");
  return fetchSite !== "cross-site";
}

function securityResponse(request: NextRequest): NextResponse | null {
  const { pathname } = request.nextUrl;
  const isMobileApi = pathname.startsWith("/api/v1/");

  if (pathname.startsWith("/api/")) {
    const contentLength = Number(request.headers.get("content-length") ?? 0);
    if (contentLength > MAX_API_BODY_BYTES) {
      return NextResponse.json(
        isMobileApi
          ? {
              error: {
                code: "payload_too_large",
                message: "Request body too large",
              },
            }
          : { error: "Request body too large" },
        {
          status: 413,
          headers: isMobileApi
            ? { "Cache-Control": "private, no-store, max-age=0" }
            : undefined,
        },
      );
    }

    if (
      isUnsafeMethod(request.method) &&
      !pathname.startsWith("/api/auth") &&
      !isWebhookPath(pathname) &&
      !isSameOrigin(request)
    ) {
      return NextResponse.json({ error: "Forbidden" }, { status: 403 });
    }
  }

  const rateLimitName =
    request.method === "POST" && pathname === "/api/signup"
      ? "signup"
      : request.method === "POST" && pathname === "/api/v1/auth/session"
        ? "mobileLogin"
      : request.method === "POST" &&
          pathname === "/api/auth/callback/credentials"
        ? "login"
        : null;

  if (rateLimitName) {
    const result = rateLimit(rateLimitName, request);
    if (result.limited) {
      return NextResponse.json(
        rateLimitName === "mobileLogin"
          ? {
              error: {
                code: "rate_limited",
                message: "Too many requests",
              },
            }
          : { error: "Too many requests" },
        {
          status: 429,
          headers: {
            "Retry-After": String(result.retryAfter),
            ...(rateLimitName === "mobileLogin"
              ? { "Cache-Control": "private, no-store, max-age=0" }
              : {}),
          },
        },
      );
    }
  }

  return null;
}

export default withAuth((req) => securityResponse(req));

export const config = {
  matcher: [
    // Exclude static assets and Next internals. Public auth/OAuth/webhook
    // routes still pass through proxy security checks and are allowed by
    // authConfig.authorized.
    "/((?!_next/static|_next/image|favicon.ico|robots.txt|manifest.json|icons/|.*\\.(?:svg|png|jpg|jpeg|gif|webp|ico)$).*)",
  ],
};
