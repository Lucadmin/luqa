import { NextResponse } from "next/server";
import { getUserId } from "@/lib/api-auth";
import { db } from "@/lib/db";
import { toSleepDTO } from "@/lib/serializers";
import { updateSleepSchema } from "@/lib/validations";

type Params = { params: Promise<{ id: string }> };

function minutesBetween(start: Date, end: Date): number {
  return Math.max(0, Math.round((end.getTime() - start.getTime()) / 60000));
}

// PATCH /api/sleep/:id — manually correct a synced or imported sleep session.
export async function PATCH(request: Request, { params }: Params) {
  const userId = await getUserId();
  if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const { id } = await params;

  let body: unknown;
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: "Invalid JSON" }, { status: 400 });
  }

  const parsed = updateSleepSchema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json(
      { error: "Invalid input", issues: parsed.error.flatten() },
      { status: 400 },
    );
  }

  const existing = await db.sleepEntry.findFirst({
    where: { id, userId, deletedAt: null },
  });
  if (!existing) {
    return NextResponse.json({ error: "Not found" }, { status: 404 });
  }

  const patch = parsed.data;
  const startTime = patch.startTime ? new Date(patch.startTime) : existing.startTime;
  const endTime = patch.endTime ? new Date(patch.endTime) : existing.endTime;
  if (endTime <= startTime) {
    return NextResponse.json(
      { error: "End must be after start" },
      { status: 400 },
    );
  }

  const awakeMinutes = patch.awakeMinutes ?? existing.awakeMinutes;
  const sleepMinutes =
    patch.sleepMinutes ??
    (patch.startTime || patch.endTime
      ? Math.max(0, minutesBetween(startTime, endTime) - (awakeMinutes ?? 0))
      : existing.sleepMinutes);

  const updated = await db.sleepEntry.update({
    where: { id },
    data: {
      ...(patch.title !== undefined ? { title: patch.title ?? null } : {}),
      ...(patch.startTime !== undefined ? { startTime } : {}),
      ...(patch.endTime !== undefined ? { endTime } : {}),
      sleepMinutes,
      awakeMinutes,
      ...(patch.lightMinutes !== undefined ? { lightMinutes: patch.lightMinutes } : {}),
      ...(patch.deepMinutes !== undefined ? { deepMinutes: patch.deepMinutes } : {}),
      ...(patch.remMinutes !== undefined ? { remMinutes: patch.remMinutes } : {}),
      manualOverrideAt: new Date(),
    },
  });

  return NextResponse.json({ entry: toSleepDTO(updated) });
}
