import { NextResponse } from "next/server";
import { getUserId } from "@/lib/api-auth";
import { db } from "@/lib/db";
import { toLifePeriodDTO } from "@/lib/serializers";
import { createLifePeriodSchema } from "@/lib/validations";

function toUtcDate(key: string): Date {
  return new Date(`${key}T00:00:00.000Z`);
}

// POST /api/life/periods — create a life period (chapter band).
export async function POST(request: Request) {
  const userId = await getUserId();
  if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  let body: unknown;
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: "Invalid JSON" }, { status: 400 });
  }

  const parsed = createLifePeriodSchema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json(
      { error: "Invalid input", issues: parsed.error.flatten() },
      { status: 400 },
    );
  }
  const d = parsed.data;

  const period = await db.lifePeriod.create({
    data: {
      userId,
      name: d.name,
      ...(d.color ? { color: d.color } : {}),
      startDate: toUtcDate(d.startDate),
      endDate: d.endDate ? toUtcDate(d.endDate) : null,
    },
  });

  return NextResponse.json({ period: toLifePeriodDTO(period) }, { status: 201 });
}
