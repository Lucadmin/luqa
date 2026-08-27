import {
  invalidInput,
  invalidJson,
  mobileAuthError,
  mobileJson,
  readJson,
} from "@/lib/mobile-api-response";
import { createMobileSessionSchema } from "@/lib/mobile-api-validation";
import {
  authenticateMobileRequest,
  createMobileSession,
  revokeMobileSession,
} from "@/lib/server/mobile-auth";

export async function POST(request: Request) {
  let body: unknown;
  try {
    body = await readJson(request);
  } catch {
    return invalidJson();
  }

  const parsed = createMobileSessionSchema.safeParse(body);
  if (!parsed.success) return invalidInput(parsed.error.flatten());

  try {
    const session = await createMobileSession(parsed.data);
    return mobileJson(session, { status: 201 });
  } catch (error) {
    const response = mobileAuthError(error);
    if (response) return response;
    throw error;
  }
}

export async function DELETE(request: Request) {
  try {
    const session = await authenticateMobileRequest(request);
    await revokeMobileSession(session.id);
    return new Response(null, {
      status: 204,
      headers: { "Cache-Control": "private, no-store, max-age=0" },
    });
  } catch (error) {
    const response = mobileAuthError(error);
    if (response) return response;
    throw error;
  }
}
