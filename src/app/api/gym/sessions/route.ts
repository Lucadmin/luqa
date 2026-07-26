import { NextResponse } from "next/server";
import { getUserId } from "@/lib/api-auth";
import { db } from "@/lib/db";
import { toGymSessionDTO } from "@/lib/serializers";
import { sessionInclude } from "@/lib/server/gym";

const DEFAULT_LIMIT = 20;
const MAX_LIMIT = 100;

// GET /api/gym/sessions?cursor=<id>&limit=20 — sessions newest first, a page
// at a time, for the history list's scroll-triggered loading.
export async function GET(request: Request) {
  const userId = await getUserId();
  if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const url = new URL(request.url);
  const cursor = url.searchParams.get("cursor");
  const limit = Math.min(
    MAX_LIMIT,
    Math.max(1, Number(url.searchParams.get("limit")) || DEFAULT_LIMIT),
  );

  // Ask for one extra row so "is there another page" doesn't need a count
  // query — just whether the (limit + 1)th row came back.
  const rows = await db.gymSession.findMany({
    where: { userId },
    orderBy: [{ date: "desc" }, { createdAt: "desc" }, { id: "desc" }],
    take: limit + 1,
    ...(cursor ? { cursor: { id: cursor }, skip: 1 } : {}),
    include: sessionInclude,
  });

  const hasMore = rows.length > limit;
  const page = hasMore ? rows.slice(0, limit) : rows;

  return NextResponse.json({
    sessions: page.map(toGymSessionDTO),
    nextCursor: hasMore ? page[page.length - 1].id : null,
  });
}
