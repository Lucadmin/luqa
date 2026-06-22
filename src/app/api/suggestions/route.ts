import { NextResponse } from "next/server";
import { getUserId } from "@/lib/api-auth";
import { db } from "@/lib/db";
import type { SuggestionDTO } from "@/lib/types";

// GET /api/suggestions?q= — recent description+category combos, for the
// timer's autocomplete. The list naturally grows as the user tracks.
export async function GET(request: Request) {
  const userId = await getUserId();
  if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const { searchParams } = new URL(request.url);
  const q = searchParams.get("q")?.trim();

  const rows = await db.timeEntry.findMany({
    where: {
      userId,
      deletedAt: null,
      description: q
        ? { contains: q, mode: "insensitive", not: "" }
        : { not: "" },
    },
    orderBy: { startTime: "desc" },
    distinct: ["description", "categoryId"],
    select: { description: true, categoryId: true },
    take: 20,
  });

  const suggestions: SuggestionDTO[] = rows.map((r) => ({
    description: r.description,
    categoryId: r.categoryId,
  }));

  return NextResponse.json({ suggestions });
}
