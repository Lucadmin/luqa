import { NextResponse } from "next/server";
import { getUserId } from "@/lib/api-auth";
import { db } from "@/lib/db";
import { toSettlementDTO } from "@/lib/serializers";
import { dateFromKey } from "@/lib/server/money";
import { updateSettlementSchema } from "@/lib/validations";

// PATCH /api/money/settlements/[id] — correct a payback.
export async function PATCH(
  request: Request,
  { params }: { params: Promise<{ id: string }> },
) {
  const userId = await getUserId();
  if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const { id } = await params;
  const existing = await db.settlement.findFirst({ where: { id, userId } });
  if (!existing) return NextResponse.json({ error: "Not found" }, { status: 404 });

  let body: unknown;
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: "Invalid JSON" }, { status: 400 });
  }

  const parsed = updateSettlementSchema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json(
      { error: "Invalid input", issues: parsed.error.flatten() },
      { status: 400 },
    );
  }
  const d = parsed.data;

  const settlement = await db.settlement.update({
    where: { id },
    data: {
      ...(d.amountCents !== undefined ? { amountCents: d.amountCents } : {}),
      ...(d.direction !== undefined ? { direction: d.direction } : {}),
      ...(d.date !== undefined ? { date: dateFromKey(d.date) } : {}),
      ...(d.notes !== undefined ? { notes: d.notes } : {}),
    },
  });

  return NextResponse.json({ settlement: toSettlementDTO(settlement) });
}

// DELETE /api/money/settlements/[id] — undo a payback.
export async function DELETE(
  _request: Request,
  { params }: { params: Promise<{ id: string }> },
) {
  const userId = await getUserId();
  if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const { id } = await params;
  const settlement = await db.settlement.findFirst({ where: { id, userId } });
  if (!settlement) return NextResponse.json({ error: "Not found" }, { status: 404 });

  await db.settlement.update({
    where: { id },
    data: { deletedAt: new Date() },
  });
  return new NextResponse(null, { status: 204 });
}
