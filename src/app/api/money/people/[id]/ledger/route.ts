import { NextResponse } from "next/server";
import { getUserId } from "@/lib/api-auth";
import { personLedger } from "@/lib/server/money";

// GET /api/money/people/[id]/ledger — one person's whole history with the
// user, plus the balance and treat totals it adds up to.
export async function GET(
  _request: Request,
  { params }: { params: Promise<{ id: string }> },
) {
  const userId = await getUserId();
  if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const { id } = await params;
  const ledger = await personLedger(userId, id);
  if (!ledger) return NextResponse.json({ error: "Not found" }, { status: 404 });

  return NextResponse.json({ ledger });
}
