import { NextResponse } from "next/server";
import { getUserId } from "@/lib/api-auth";
import { db } from "@/lib/db";
import { toWeekNoteDTO } from "@/lib/serializers";
import { upsertWeekNoteSchema } from "@/lib/validations";

// POST /api/life/notes — upsert one week's review by week index. When the note
// carries no content at all, the row is deleted instead (so clearing a week
// removes its marker from the grid).
export async function POST(request: Request) {
  const userId = await getUserId();
  if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  let body: unknown;
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: "Invalid JSON" }, { status: 400 });
  }

  const parsed = upsertWeekNoteSchema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json(
      { error: "Invalid input", issues: parsed.error.flatten() },
      { status: 400 },
    );
  }
  const d = parsed.data;
  const highlights = d.highlights.trim();
  const lessons = d.lessons.trim();
  const milestone = d.milestone?.trim() || null;
  const rating = d.rating ?? null;

  const isEmpty = !highlights && !lessons && !milestone && rating === null;

  if (isEmpty) {
    await db.weekNote.deleteMany({ where: { userId, weekIndex: d.weekIndex } });
    return NextResponse.json({ deleted: true, weekIndex: d.weekIndex });
  }

  const note = await db.weekNote.upsert({
    where: { userId_weekIndex: { userId, weekIndex: d.weekIndex } },
    create: { userId, weekIndex: d.weekIndex, highlights, lessons, rating, milestone },
    update: { highlights, lessons, rating, milestone },
  });

  return NextResponse.json({ note: toWeekNoteDTO(note) });
}
