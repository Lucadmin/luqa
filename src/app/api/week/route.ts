import { NextResponse } from "next/server";
import { getUserId } from "@/lib/api-auth";
import { db } from "@/lib/db";
import { toCategoryDTO, toEntryDTO } from "@/lib/serializers";

// GET /api/week?from=ISO&to=ISO
// Returns entries + per-category totals for a date range (typically 7 days).
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

  const [entries, categories] = await Promise.all([
    db.timeEntry.findMany({
      where: {
        userId,
        deletedAt: null,
        startTime: { gte: fromDate, lt: toDate },
        endTime: { not: null },
      },
      orderBy: { startTime: "asc" },
    }),
    db.category.findMany({
      where: { userId, archived: false },
      orderBy: { name: "asc" },
    }),
  ]);

  // Per-category totals in minutes.
  const totalsByCategory: Record<string, number> = {};
  let totalMinutes = 0;
  for (const entry of entries) {
    if (!entry.endTime) continue;
    const mins = (entry.endTime.getTime() - entry.startTime.getTime()) / 60000;
    totalMinutes += mins;
    const key = entry.categoryId ?? "__none__";
    totalsByCategory[key] = (totalsByCategory[key] ?? 0) + mins;
  }

  return NextResponse.json({
    entries: entries.map(toEntryDTO),
    categories: categories.map(toCategoryDTO),
    totalsByCategory,
    totalMinutes,
  });
}
