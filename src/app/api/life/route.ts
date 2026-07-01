import { NextResponse } from "next/server";
import { getUserId } from "@/lib/api-auth";
import { db } from "@/lib/db";
import { toDateKey } from "@/lib/life";
import { toLifePeriodDTO, toWeekNoteDTO } from "@/lib/serializers";
import type { LifeOverviewDTO } from "@/lib/types";

// GET /api/life — everything the life overview needs: birth date, the grid
// height, all periods, and all week notes, in one payload.
export async function GET() {
  const userId = await getUserId();
  if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const [user, periods, notes] = await Promise.all([
    db.user.findUnique({
      where: { id: userId },
      select: { birthDate: true, lifeExpectancyYears: true },
    }),
    db.lifePeriod.findMany({
      where: { userId },
      orderBy: [{ startDate: "asc" }, { createdAt: "asc" }],
    }),
    db.weekNote.findMany({
      where: { userId },
      orderBy: { weekIndex: "asc" },
    }),
  ]);

  if (!user) return NextResponse.json({ error: "Not found" }, { status: 404 });

  const life: LifeOverviewDTO = {
    birthDate: user.birthDate ? toDateKey(user.birthDate) : null,
    lifeExpectancyYears: user.lifeExpectancyYears,
    periods: periods.map(toLifePeriodDTO),
    notes: notes.map(toWeekNoteDTO),
  };

  return NextResponse.json({ life });
}
