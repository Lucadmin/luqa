import { NextResponse } from "next/server";
import { getUserId } from "@/lib/api-auth";
import { db } from "@/lib/db";
import { toSettlementDTO } from "@/lib/serializers";
import { dateFromKey, todayKey } from "@/lib/server/money";
import { createSettlementSchema } from "@/lib/validations";

// GET /api/money/settlements?personId= — paybacks, newest first.
export async function GET(request: Request) {
  const userId = await getUserId();
  if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const personId = new URL(request.url).searchParams.get("personId");

  const settlements = await db.settlement.findMany({
    where: { userId, ...(personId ? { personId } : {}) },
    orderBy: [{ date: "desc" }, { createdAt: "desc" }],
    take: 100,
  });

  return NextResponse.json({ settlements: settlements.map(toSettlementDTO) });
}

// POST /api/money/settlements — record a payback. It moves the balance without
// touching any of the expenses behind it, so the history stays readable.
export async function POST(request: Request) {
  const userId = await getUserId();
  if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  let body: unknown;
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: "Invalid JSON" }, { status: 400 });
  }

  const parsed = createSettlementSchema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json(
      { error: "Invalid input", issues: parsed.error.flatten() },
      { status: 400 },
    );
  }
  const d = parsed.data;

  const person = await db.person.findFirst({
    where: { id: d.personId, userId },
    select: { id: true },
  });
  if (!person) return NextResponse.json({ error: "Unknown person" }, { status: 400 });

  const settlement = await db.settlement.create({
    data: {
      userId,
      personId: d.personId,
      amountCents: d.amountCents,
      direction: d.direction,
      date: dateFromKey(d.date ?? todayKey()),
      notes: d.notes,
    },
  });

  return NextResponse.json({ settlement: toSettlementDTO(settlement) }, { status: 201 });
}
