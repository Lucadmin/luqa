import {
  invalidInput,
  invalidJson,
  mobileAuthError,
  mobileJson,
  readJson,
} from "@/lib/mobile-api-response";
import { authenticateMobileRequest } from "@/lib/server/mobile-auth";
import {
  InvalidCategoryError,
  createTimeEntry,
  listTimeEntries,
  parseEntryWindow,
} from "@/lib/server/today";
import { createEntrySchema } from "@/lib/validations";

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

  const entries = await listTimeEntries(session.userId, window);
  return mobileJson({ entries });
}

export async function POST(request: Request) {
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
  const parsed = createEntrySchema.safeParse(body);
  if (!parsed.success) return invalidInput(parsed.error.flatten());

  try {
    const entry = await createTimeEntry(session.userId, parsed.data);
    return mobileJson({ entry }, { status: 201 });
  } catch (error) {
    if (error instanceof InvalidCategoryError) {
      return mobileJson(
        {
          error: {
            code: "unknown_category",
            message: "Unknown category",
          },
        },
        { status: 400 },
      );
    }
    throw error;
  }
}
