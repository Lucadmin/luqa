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
import { updateGymLocationSchema } from "@/lib/validations";

export async function PATCH(
  request: Request,
  { params }: { params: Promise<{ id: string }> },
) {
  let mobileSession;
  try {
    mobileSession = await authenticateMobileRequest(request);
  } catch (error) {
    const response = mobileAuthError(error);
    if (response) return response;
    throw error;
  }
  const { id } = await params;
  const existing = await db.gymLocation.findFirst({
    where: { id, userId: mobileSession.userId },
    select: { id: true },
  });
  if (!existing) {
    return mobileJson(
      { error: { code: "not_found", message: "Gym not found" } },
      { status: 404 },
    );
  }
  let body: unknown;
  try {
    body = await readJson(request);
  } catch {
    return invalidJson();
  }
  const parsed = updateGymLocationSchema.safeParse(body);
  if (!parsed.success) return invalidInput(parsed.error.flatten());
  const input = parsed.data;
  const location = await db.gymLocation.update({
    where: { id },
    data: {
      ...(input.code !== undefined ? { code: input.code } : {}),
      ...(input.name !== undefined ? { name: input.name } : {}),
      ...(input.color !== undefined ? { color: input.color } : {}),
      ...(input.order !== undefined ? { order: input.order } : {}),
      ...(input.archived !== undefined
        ? { archivedAt: input.archived ? new Date() : null }
        : {}),
    },
  });
  return mobileJson({ location: toGymLocationDTO(location) });
}
