import {
  invalidInput,
  invalidJson,
  mobileAuthError,
  mobileJson,
  readJson,
} from "@/lib/mobile-api-response";
import { authenticateMobileRequest } from "@/lib/server/mobile-auth";
import { createCategory, listCategories } from "@/lib/server/today";
import { createCategorySchema } from "@/lib/validations";

export async function GET(request: Request) {
  try {
    const session = await authenticateMobileRequest(request);
    const categories = await listCategories(session.userId);
    return mobileJson({ categories });
  } catch (error) {
    const response = mobileAuthError(error);
    if (response) return response;
    throw error;
  }
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
  const parsed = createCategorySchema.safeParse(body);
  if (!parsed.success) return invalidInput(parsed.error.flatten());

  const result = await createCategory(session.userId, parsed.data);
  return mobileJson(
    { category: result.category },
    { status: result.created ? 201 : 200 },
  );
}
