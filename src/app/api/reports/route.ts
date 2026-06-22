import { NextResponse } from "next/server";
import { getUserId } from "@/lib/api-auth";
import { db } from "@/lib/db";
import { toCategoryDTO } from "@/lib/serializers";
import { isoDateKey } from "@/lib/time";

// GET /api/reports?from=ISO&to=ISO
// Daily totals + per-category breakdown for a date range.
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

  const [entries, categories] = await Promise.all([
    db.timeEntry.findMany({
      where: {
        userId,
        deletedAt: null,
        startTime: { gte: fromDate, lt: toDate },
        endTime: { not: null },
      },
    }),
    db.category.findMany({
      where: { userId, archived: false },
      orderBy: { name: "asc" },
    }),
  ]);

  // Daily totals: { "2025-06-10": minutes }
  const dailyTotals: Record<string, number> = {};
  // Per-category total across the whole range
  const totalsByCategory: Record<string, number> = {};
  // Per-day, per-category breakdown: { "2025-06-10": { catId: minutes } }
  const dailyByCategory: Record<string, Record<string, number>> = {};
  let totalMinutes = 0;

  for (const e of entries) {
    if (!e.endTime) continue;
    const mins = (e.endTime.getTime() - e.startTime.getTime()) / 60000;
    totalMinutes += mins;

    const dayKey = isoDateKey(e.startTime);
    dailyTotals[dayKey] = (dailyTotals[dayKey] ?? 0) + mins;

    const catKey = e.categoryId ?? "__none__";
    totalsByCategory[catKey] = (totalsByCategory[catKey] ?? 0) + mins;

    if (!dailyByCategory[dayKey]) dailyByCategory[dayKey] = {};
    dailyByCategory[dayKey][catKey] = (dailyByCategory[dayKey][catKey] ?? 0) + mins;
  }

  return NextResponse.json({
    categories: categories.map(toCategoryDTO),
    totalsByCategory,
    dailyTotals,
    dailyByCategory,
    totalMinutes,
  });
}
