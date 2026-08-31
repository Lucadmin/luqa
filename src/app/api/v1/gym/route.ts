import { mobileAuthError, mobileJson } from "@/lib/mobile-api-response";
import { gymOverview } from "@/lib/server/gym";
import { authenticateMobileRequest } from "@/lib/server/mobile-auth";

const DEFAULT_LIMIT = 30;
const MAX_LIMIT = 100;

export async function GET(request: Request) {
  try {
    const session = await authenticateMobileRequest(request);
    const url = new URL(request.url);
    const limit = Math.min(
      MAX_LIMIT,
      Math.max(1, Number(url.searchParams.get("limit")) || DEFAULT_LIMIT),
    );
    return mobileJson({ overview: await gymOverview(session.userId, limit) });
  } catch (error) {
    const response = mobileAuthError(error);
    if (response) return response;
    throw error;
  }
}
