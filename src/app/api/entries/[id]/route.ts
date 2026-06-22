import { NextResponse } from "next/server";
import { getUserId } from "@/lib/api-auth";
import { db } from "@/lib/db";
import { pushEntryDelete, pushEntryUpdate } from "@/lib/google/push-sync";
import { toEntryDTO } from "@/lib/serializers";
import { updateEntrySchema } from "@/lib/validations";

type Params = { params: Promise<{ id: string }> };

// PATCH /api/entries/:id — edit description, category, or times.
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

  const parsed = updateEntrySchema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json(
      { error: "Invalid input", issues: parsed.error.flatten() },
      { status: 400 },
    );
  }

  const existing = await db.timeEntry.findFirst({
    where: { id, userId, deletedAt: null },
  });
  if (!existing) {
    return NextResponse.json({ error: "Not found" }, { status: 404 });
  }

  const { description, categoryId, startTime, endTime } = parsed.data;

  if (categoryId) {
    const owns = await db.category.findFirst({
      where: { id: categoryId, userId },
      select: { id: true },
    });
    if (!owns) {
      return NextResponse.json({ error: "Unknown category" }, { status: 400 });
    }
  }

  // Validate the resulting start/end pair (one side may be unchanged).
  const nextStart = startTime ? new Date(startTime) : existing.startTime;
  const nextEnd =
    endTime === undefined
      ? existing.endTime
      : endTime === null
        ? null
        : new Date(endTime);
  if (nextEnd && nextEnd <= nextStart) {
    return NextResponse.json(
      { error: "End must be after start" },
      { status: 400 },
    );
  }

  const updated = await db.timeEntry.update({
    where: { id },
    data: {
      ...(description !== undefined ? { description } : {}),
      ...(categoryId !== undefined ? { categoryId } : {}),
      ...(startTime !== undefined ? { startTime: nextStart } : {}),
      ...(endTime !== undefined ? { endTime: nextEnd } : {}),
    },
  });

  // Push update to Google Calendar (fire-and-forget).
  if (updated.endTime) {
    void pushEntryUpdate(
      userId,
      updated.id,
      updated.description,
      updated.categoryId,
      updated.startTime.toISOString(),
      updated.endTime.toISOString(),
    );
  }

  return NextResponse.json({ entry: toEntryDTO(updated) });
}

// DELETE /api/entries/:id — soft delete + propagate to Google Calendar.
export async function DELETE(_request: Request, { params }: Params) {
  const userId = await getUserId();
  if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const { id } = await params;

  const existing = await db.timeEntry.findFirst({
    where: { id, userId, deletedAt: null },
    select: { id: true, googleEventId: true },
  });
  if (!existing) {
    return NextResponse.json({ error: "Not found" }, { status: 404 });
  }

  await db.timeEntry.update({
    where: { id },
    data: { deletedAt: new Date() },
  });

  // Remove from Google Calendar (fire-and-forget).
  if (existing.googleEventId) {
    void pushEntryDelete(userId, existing.googleEventId);
  }

  return NextResponse.json({ ok: true });
}
