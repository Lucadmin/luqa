import { NextResponse } from "next/server";
import type { Prisma } from "@/generated/prisma/client";
import { getUserId } from "@/lib/api-auth";
import { db } from "@/lib/db";
import { toPersonDTO } from "@/lib/serializers";
import { updatePersonSchema } from "@/lib/validations";

// PATCH /api/money/people/[id] — rename, restyle, change the default cut,
// reorder, archive or restore.
export async function PATCH(
  request: Request,
  { params }: { params: Promise<{ id: string }> },
) {
  const userId = await getUserId();
  if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const { id } = await params;
  const existing = await db.person.findFirst({ where: { id, userId } });
  if (!existing) return NextResponse.json({ error: "Not found" }, { status: 404 });

  let body: unknown;
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: "Invalid JSON" }, { status: 400 });
  }

  const parsed = updatePersonSchema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json(
      { error: "Invalid input", issues: parsed.error.flatten() },
      { status: 400 },
    );
  }
  const d = parsed.data;

  if (d.name !== undefined && d.name !== existing.name) {
    const taken = await db.person.findFirst({
      where: { userId, name: d.name, id: { not: id } },
      select: { id: true },
    });
    if (taken) {
      return NextResponse.json(
        { error: `You already have someone called ${d.name}` },
        { status: 409 },
      );
    }
  }

  const data: Prisma.PersonUpdateInput = {};
  if (d.name !== undefined) data.name = d.name;
  if (d.color !== undefined) data.color = d.color;
  if (d.emoji !== undefined) data.emoji = d.emoji ?? null;
  if (d.defaultPercent !== undefined) data.defaultPercent = d.defaultPercent ?? null;
  if (d.order !== undefined) data.order = d.order;
  if (d.archived !== undefined) data.archivedAt = d.archived ? new Date() : null;

  const person = await db.person.update({ where: { id }, data });
  return NextResponse.json({ person: toPersonDTO(person) });
}

// DELETE /api/money/people/[id] — remove someone.
//
// Anyone who has been on a bill is archived rather than deleted, so the
// history that produced their balance survives. Someone added by mistake, with
// nothing attached, is removed outright.
export async function DELETE(
  _request: Request,
  { params }: { params: Promise<{ id: string }> },
) {
  const userId = await getUserId();
  if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const { id } = await params;
  const person = await db.person.findFirst({ where: { id, userId } });
  if (!person) return NextResponse.json({ error: "Not found" }, { status: 404 });

  const [shares, paid, settlements] = await Promise.all([
    db.expenseShare.count({ where: { personId: id } }),
    db.expense.count({ where: { paidByPersonId: id } }),
    db.settlement.count({ where: { personId: id } }),
  ]);

  if (shares + paid + settlements === 0) {
    await db.person.delete({ where: { id } });
    return NextResponse.json({ deleted: true });
  }

  await db.person.update({ where: { id }, data: { archivedAt: new Date() } });
  return NextResponse.json({ deleted: false });
}
