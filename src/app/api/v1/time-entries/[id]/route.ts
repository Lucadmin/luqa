import {
  invalidInput,
  invalidJson,
  mobileAuthError,
  mobileJson,
  readJson,
} from "@/lib/mobile-api-response";
import { authenticateMobileRequest } from "@/lib/server/mobile-auth";
import {
  EntryRangeError,
  InvalidCategoryError,
  deleteTimeEntry,
  updateTimeEntry,
} from "@/lib/server/today";
import { updateEntrySchema } from "@/lib/validations";

type Params = { params: Promise<{ id: string }> };

function notFound() {
  return mobileJson(
    { error: { code: "not_found", message: "Time entry not found" } },
    { status: 404 },
  );
}

export async function PATCH(request: Request, { params }: Params) {
  let session;
  try {
    session = await authenticateMobileRequest(request);
  } catch (error) {
    const response = mobileAuthError(error);
    if (response) return response;
    throw error;
  }

  let body: unknown;
  try {
    body = await readJson(request);
  } catch {
    return invalidJson();
  }
  const parsed = updateEntrySchema.safeParse(body);
  if (!parsed.success) return invalidInput(parsed.error.flatten());

  const { id } = await params;
  try {
    const entry = await updateTimeEntry(session.userId, id, parsed.data);
    if (!entry) return notFound();
    return mobileJson({ entry });
  } catch (error) {
    if (error instanceof InvalidCategoryError) {
      return mobileJson(
        { error: { code: "unknown_category", message: "Unknown category" } },
        { status: 400 },
      );
    }
    if (error instanceof EntryRangeError) {
      return mobileJson(
        { error: { code: "invalid_range", message: error.message } },
        { status: 400 },
      );
    }
    throw error;
  }
}

export async function DELETE(request: Request, { params }: Params) {
  let session;
  try {
    session = await authenticateMobileRequest(request);
  } catch (error) {
    const response = mobileAuthError(error);
    if (response) return response;
    throw error;
  }

  const { id } = await params;
  const deleted = await deleteTimeEntry(session.userId, id);
  if (!deleted) return notFound();

  // 204 carries no body, so the private cache headers ride on a bare Response.
  return new Response(null, {
    status: 204,
    headers: { "Cache-Control": "private, no-store, max-age=0" },
  });
}
