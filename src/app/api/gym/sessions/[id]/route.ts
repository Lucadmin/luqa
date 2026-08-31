import { NextResponse } from "next/server";
import { getUserId } from "@/lib/api-auth";
import { db } from "@/lib/db";
import { toGymSessionDTO } from "@/lib/serializers";
import { dateFromKey } from "@/lib/server/money";
import {
  namesToResolve,
  ownedExerciseIds,
  resolveExerciseIds,
  sessionInclude,
  writeSessionExercises,
} from "@/lib/server/gym";
import { updateGymSessionSchema } from "@/lib/validations";

async function ownedSession(userId: string, id: string) {
  return db.gymSession.findFirst({ where: { id, userId }, select: { id: true } });
}

// GET /api/gym/sessions/:id
export async function GET(
  _request: Request,
  { params }: { params: Promise<{ id: string }> },
) {
  const userId = await getUserId();
  if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const { id } = await params;
  const session = await db.gymSession.findFirst({
    where: { id, userId },
    include: sessionInclude,
  });
  if (!session) return NextResponse.json({ error: "Not found" }, { status: 404 });

  return NextResponse.json({ session: toGymSessionDTO(session) });
}

// PATCH /api/gym/sessions/:id — sending `exercises` replaces the whole list,
// which is how the editor saves: the form owns the session's contents.
export async function PATCH(
  request: Request,
  { params }: { params: Promise<{ id: string }> },
) {
  const userId = await getUserId();
  if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const { id } = await params;
  if (!(await ownedSession(userId, id))) {
    return NextResponse.json({ error: "Not found" }, { status: 404 });
  }

  let body: unknown;
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: "Invalid JSON" }, { status: 400 });
  }

  const parsed = updateGymSessionSchema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json(
      { error: "Invalid input", issues: parsed.error.flatten() },
      { status: 400 },
    );
  }
  const d = parsed.data;

  if (d.locationId) {
    const owns = await db.gymLocation.findFirst({
      where: { id: d.locationId, userId },
      select: { id: true },
    });
    if (!owns) return NextResponse.json({ error: "Unknown gym" }, { status: 400 });
  }

  const exercises = d.exercises;
  let idByKey = new Map<string, string>();

  if (exercises) {
    const referenced = exercises.flatMap((e) => (e.exerciseId ? [e.exerciseId] : []));
    const owned = await ownedExerciseIds(userId, referenced);
    if (referenced.some((eid) => !owned.has(eid))) {
      return NextResponse.json({ error: "Unknown exercise" }, { status: 400 });
    }
    idByKey = await resolveExerciseIds(userId, namesToResolve(exercises));
  }

  const session = await db.$transaction(async (tx) => {
    await tx.gymSession.update({
      where: { id },
      data: {
        ...(d.date !== undefined ? { date: dateFromKey(d.date) } : {}),
        ...(d.locationId !== undefined ? { locationId: d.locationId ?? null } : {}),
        ...(d.notes !== undefined ? { notes: d.notes } : {}),
      },
    });

    if (exercises) await writeSessionExercises(tx, id, exercises, idByKey);

    return tx.gymSession.findUniqueOrThrow({
      where: { id },
      include: sessionInclude,
    });
  });

  return NextResponse.json({ session: toGymSessionDTO(session) });
}

// DELETE /api/gym/sessions/:id
export async function DELETE(
  _request: Request,
  { params }: { params: Promise<{ id: string }> },
) {
  const userId = await getUserId();
  if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const { id } = await params;
  if (!(await ownedSession(userId, id))) {
    return NextResponse.json({ error: "Not found" }, { status: 404 });
  }

  await db.gymSession.update({
    where: { id },
    data: { deletedAt: new Date() },
  });

  return NextResponse.json({ deleted: true });
}
