import assert from "node:assert/strict";
import test from "node:test";

import {
  MOBILE_ACCESS_TOKEN_TTL_MS,
  MOBILE_REFRESH_TOKEN_TTL_MS,
  bearerToken,
  createMobileTokenPair,
  hashMobileToken,
  isMobileAccessToken,
  isMobileRefreshToken,
} from "../../src/lib/mobile-auth-tokens.ts";

test("creates distinct opaque access and refresh credentials", () => {
  const now = new Date("2026-08-27T12:00:00.000Z");
  const first = createMobileTokenPair(now);
  const second = createMobileTokenPair(now);

  assert.equal(isMobileAccessToken(first.accessToken), true);
  assert.equal(isMobileRefreshToken(first.refreshToken), true);
  assert.notEqual(first.accessToken, second.accessToken);
  assert.notEqual(first.refreshToken, second.refreshToken);
  assert.equal(first.accessTokenHash, hashMobileToken(first.accessToken));
  assert.equal(first.refreshTokenHash, hashMobileToken(first.refreshToken));
  assert.equal(
    first.accessExpiresAt.getTime() - now.getTime(),
    MOBILE_ACCESS_TOKEN_TTL_MS,
  );
  assert.equal(
    first.refreshExpiresAt.getTime() - now.getTime(),
    MOBILE_REFRESH_TOKEN_TTL_MS,
  );
});

test("accepts only an exact bearer authorization value", () => {
  assert.equal(bearerToken("Bearer token-value"), "token-value");
  assert.equal(bearerToken("bearer token-value"), null);
  assert.equal(bearerToken("Bearer token value"), null);
  assert.equal(bearerToken(null), null);
});
