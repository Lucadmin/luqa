import { mobileAuthError, mobileJson } from "@/lib/mobile-api-response";
import { exerciseHistory } from "@/lib/server/gym";
import { authenticateMobileRequest } from "@/lib/server/mobile-auth";

export async function GET(
  request: Request,
  { params }: { params: Promise<{ id: string }> },
) {
  try {
    const mobileSession = await authenticateMobileRequest(request);
    const { id } = await params;
    const url = new URL(request.url);
    const history = await exerciseHistory(mobileSession.userId, id, {
      locationId: url.searchParams.get("locationId"),
      beforeSessionId: url.searchParams.get("beforeSessionId"),
    });
    if (!history) {
      return mobileJson(
        { error: { code: "not_found", message: "Exercise not found" } },
        { status: 404 },
      );
    }
    return mobileJson({ history });
  } catch (error) {
    const response = mobileAuthError(error);
    if (response) return response;
    throw error;
  }
}
