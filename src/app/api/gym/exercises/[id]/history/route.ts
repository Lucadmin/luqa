import { NextResponse } from "next/server";
import { getUserId } from "@/lib/api-auth";
import { exerciseHistory } from "@/lib/server/gym";

// GET /api/gym/exercises/:id/history?locationId=…
//
// The location filter matters more than it looks: a stack marked 70 at one gym
// is nothing like a 70 at another, so comparing across gyms can be nonsense.
// Passing a gym narrows the history to it; omitting it shows everything.
export async function GET(
  request: Request,
  { params }: { params: Promise<{ id: string }> },
) {
  const userId = await getUserId();
  if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const { id } = await params;
  const locationId = new URL(request.url).searchParams.get("locationId");
  const history = await exerciseHistory(userId, id, { locationId });
  if (!history) return NextResponse.json({ error: "Not found" }, { status: 404 });

  return NextResponse.json({ history });
}
