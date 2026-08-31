import { db } from "@/lib/db";
import {
  invalidInput,
  invalidJson,
  mobileAuthError,
  mobileJson,
  readJson,
} from "@/lib/mobile-api-response";
import { toGymLocationDTO } from "@/lib/serializers";
import { authenticateMobileRequest } from "@/lib/server/mobile-auth";
import { createGymLocationSchema } from "@/lib/validations";

export async function POST(request: Request) {
  let mobileSession;
  try {
    mobileSession = await authenticateMobileRequest(request);
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
  const parsed = createGymLocationSchema.safeParse(body);
  if (!parsed.success) return invalidInput(parsed.error.flatten());
  const maxOrder = await db.gymLocation.aggregate({
    where: { userId: mobileSession.userId },
    _max: { order: true },
  });
  const location = await db.gymLocation.create({
    data: {
      userId: mobileSession.userId,
      ...parsed.data,
      order: (maxOrder._max.order ?? -1) + 1,
    },
  });
  return mobileJson({ location: toGymLocationDTO(location) }, { status: 201 });
}
