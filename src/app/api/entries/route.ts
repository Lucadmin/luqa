import { NextResponse } from "next/server";
import { getUserId } from "@/lib/api-auth";
import { db } from "@/lib/db";
import { toEntryDTO } from "@/lib/serializers";
import { createEntrySchema } from "@/lib/validations";

// GET /api/entries?from=ISO&to=ISO
// Returns entries overlapping [from, to), plus any still-running entry.
export async function GET(request: Request) {
  const userId = await getUserId();
  if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const { searchParams } = new URL(request.url);
  const from = searchParams.get("from");
  const to = searchParams.get("to");
  if (!from || !to) {
    return NextResponse.json({ error: "from and to are required" }, { status: 400 });
  }

  const fromDate = new Date(from);
  const toDate = new Date(to);
  if (Number.isNaN(fromDate.getTime()) || Number.isNaN(toDate.getTime())) {
    return NextResponse.json({ error: "Invalid from/to" }, { status: 400 });
  }

  const entries = await db.timeEntry.findMany({
    where: {
      userId,
      deletedAt: null,
      startTime: { lt: toDate },
      // overlaps the window: still running, or ended after `from`
      OR: [{ endTime: null }, { endTime: { gt: fromDate } }],
    },
    orderBy: { startTime: "asc" },
  });

  return NextResponse.json({ entries: entries.map(toEntryDTO) });
}

// POST /api/entries — create an entry (past block or a running timer).
export async function POST(request: Request) {
  const userId = await getUserId();
  if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  let body: unknown;
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: "Invalid JSON" }, { status: 400 });
  }

  const parsed = createEntrySchema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json(
      { error: "Invalid input", issues: parsed.error.flatten() },
      { status: 400 },
    );
  }
  const { description, categoryId, startTime, endTime } = parsed.data;

  // Guard: the category must belong to this user.
  if (categoryId) {
    const owns = await db.category.findFirst({
      where: { id: categoryId, userId },
      select: { id: true },
    });
    if (!owns) {
      return NextResponse.json({ error: "Unknown category" }, { status: 400 });
    }
  }

  const start = new Date(startTime);

  const entry = await db.$transaction(async (tx) => {
    // Starting a live timer (no end) stops any other running entry, Toggl-style.
    if (!endTime) {
      await tx.timeEntry.updateMany({
        where: { userId, endTime: null, deletedAt: null },
        data: { endTime: start },
      });
    }
    return tx.timeEntry.create({
      data: {
        userId,
        description: description ?? "",
        categoryId: categoryId ?? null,
        startTime: start,
        endTime: endTime ? new Date(endTime) : null,
        source: "APP",
      },
    });
  });

  return NextResponse.json({ entry: toEntryDTO(entry) }, { status: 201 });
}
