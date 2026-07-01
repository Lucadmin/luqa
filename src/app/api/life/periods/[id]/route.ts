import { NextResponse } from "next/server";
import type { Prisma } from "@/generated/prisma/client";
import { getUserId } from "@/lib/api-auth";
import { db } from "@/lib/db";
import { toLifePeriodDTO } from "@/lib/serializers";
import { updateLifePeriodSchema } from "@/lib/validations";

function toUtcDate(key: string): Date {
  return new Date(`${key}T00:00:00.000Z`);
}

// PATCH /api/life/periods/[id] — edit a life period.
export async function PATCH(
  request: Request,
  { params }: { params: Promise<{ id: string }> },
) {
  const userId = await getUserId();
  if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const { id } = await params;
  const existing = await db.lifePeriod.findFirst({ where: { id, userId } });
  if (!existing) return NextResponse.json({ error: "Not found" }, { status: 404 });

  let body: unknown;
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: "Invalid JSON" }, { status: 400 });
  }

  const parsed = updateLifePeriodSchema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json(
      { error: "Invalid input", issues: parsed.error.flatten() },
      { status: 400 },
    );
  }
  const d = parsed.data;
  const data: Prisma.LifePeriodUpdateInput = {};

  if (d.name !== undefined) data.name = d.name;
  if (d.color !== undefined) data.color = d.color;
  if (d.startDate !== undefined) data.startDate = toUtcDate(d.startDate);
  if (d.endDate !== undefined) data.endDate = d.endDate ? toUtcDate(d.endDate) : null;

  const period = await db.lifePeriod.update({ where: { id }, data });
  return NextResponse.json({ period: toLifePeriodDTO(period) });
}

// DELETE /api/life/periods/[id] — remove a life period.
export async function DELETE(
  _request: Request,
  { params }: { params: Promise<{ id: string }> },
) {
  const userId = await getUserId();
  if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const { id } = await params;
  const existing = await db.lifePeriod.findFirst({ where: { id, userId } });
  if (!existing) return NextResponse.json({ error: "Not found" }, { status: 404 });

  await db.lifePeriod.delete({ where: { id } });
  return NextResponse.json({ ok: true });
}
