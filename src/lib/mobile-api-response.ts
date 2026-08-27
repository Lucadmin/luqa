import { NextResponse } from "next/server";
import { MobileAuthError } from "@/lib/server/mobile-auth";

const PRIVATE_HEADERS = {
  "Cache-Control": "private, no-store, max-age=0",
  Pragma: "no-cache",
};

export function mobileJson<T>(body: T, init?: ResponseInit): NextResponse<T> {
  return NextResponse.json(body, {
    ...init,
    headers: { ...PRIVATE_HEADERS, ...init?.headers },
  });
}

export function invalidJson() {
  return mobileJson(
    { error: { code: "invalid_json", message: "Invalid JSON" } },
    { status: 400 },
  );
}

export function invalidInput(issues: unknown) {
  return mobileJson(
    {
      error: {
        code: "invalid_input",
        message: "Invalid input",
        issues,
      },
    },
    { status: 400 },
  );
}

export function mobileAuthError(error: unknown): NextResponse | null {
  if (!(error instanceof MobileAuthError)) return null;
  return mobileJson(
    { error: { code: error.code, message: error.message } },
    { status: 401 },
  );
}

export async function readJson(request: Request): Promise<unknown> {
  return request.json();
}
