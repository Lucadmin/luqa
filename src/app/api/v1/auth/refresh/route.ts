import {
  invalidInput,
  invalidJson,
  mobileAuthError,
  mobileJson,
  readJson,
} from "@/lib/mobile-api-response";
import { refreshMobileSessionSchema } from "@/lib/mobile-api-validation";
import { refreshMobileSession } from "@/lib/server/mobile-auth";

export async function POST(request: Request) {
  let body: unknown;
  try {
    body = await readJson(request);
  } catch {
    return invalidJson();
  }

  const parsed = refreshMobileSessionSchema.safeParse(body);
  if (!parsed.success) return invalidInput(parsed.error.flatten());

  try {
    const session = await refreshMobileSession(parsed.data.refreshToken);
    return mobileJson(session);
  } catch (error) {
    const response = mobileAuthError(error);
    if (response) return response;
    throw error;
  }
}
