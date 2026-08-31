import { NextResponse } from "next/server";
import { getUserId } from "@/lib/api-auth";
import { moneyOverview } from "@/lib/server/money";

// GET /api/money — the whole overview screen in one payload: everyone's
// balance, the groups and the headline totals. Expenses are paginated by their
// dedicated endpoint so the screen can keep loading the full history.
export async function GET() {
  const userId = await getUserId();
  if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  return NextResponse.json({ overview: await moneyOverview(userId) });
}
