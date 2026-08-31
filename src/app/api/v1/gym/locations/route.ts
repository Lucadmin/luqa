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
  const { id, ...input } = parsed.data;

  // A gym is identified by its code, so a repeated create — a retry, or the
  // same gym added on two devices — answers with the row that already exists
  // rather than colliding on the unique key.
  const existing = await db.gymLocation.findFirst({
    where: {
      userId: mobileSession.userId,
      OR: [{ code: input.code }, ...(id ? [{ id }] : [])],
    },
  });
  if (existing) {
    return mobileJson({ location: toGymLocationDTO(existing) }, { status: 200 });
  }

  const maxOrder = await db.gymLocation.aggregate({
    where: { userId: mobileSession.userId },
    _max: { order: true },
  });
  // The client's id is honoured only when nothing else has claimed it.
  const taken =
    id !== undefined &&
    (await db.gymLocation.findUnique({ where: { id }, select: { id: true } })) !==
      null;
  const location = await db.gymLocation.create({
    data: {
      ...(id && !taken ? { id } : {}),
      userId: mobileSession.userId,
      ...input,
      order: (maxOrder._max.order ?? -1) + 1,
    },
  });
  return mobileJson({ location: toGymLocationDTO(location) }, { status: 201 });
}
