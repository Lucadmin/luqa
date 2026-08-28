import { mobileAuthError, mobileJson } from "@/lib/mobile-api-response";
import { authenticateMobileRequest } from "@/lib/server/mobile-auth";
import { listSleepEntries, parseEntryWindow } from "@/lib/server/today";

export async function GET(request: Request) {
  let session;
  try {
    session = await authenticateMobileRequest(request);
  } catch (error) {
    const response = mobileAuthError(error);
    if (response) return response;
    throw error;
  }

  const window = parseEntryWindow(new URL(request.url).searchParams);
  if (!window.ok) {
    return mobileJson(
      { error: { code: "invalid_window", message: window.message } },
      { status: 400 },
    );
  }

  const entries = await listSleepEntries(session.userId, window);
  return mobileJson({ entries });
}
