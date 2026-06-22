import { NextResponse } from "next/server";
import { getUserId } from "@/lib/api-auth";
import { db } from "@/lib/db";
import { z } from "zod";

// GET /api/habits — list non-archived habits for the current user
export async function GET() {
  const userId = await getUserId();
  if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const habits = await db.habit.findMany({
    where: { userId, archivedAt: null },
    orderBy: [{ order: "asc" }, { createdAt: "asc" }],
  });

  return NextResponse.json({ habits });
}

const createSchema = z.object({ name: z.string().trim().min(1).max(80) });

// POST /api/habits — create a new habit
export async function POST(request: Request) {
  const userId = await getUserId();
  if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  let body: unknown;
  try { body = await request.json(); } catch {
    return NextResponse.json({ error: "Invalid JSON" }, { status: 400 });
  }

  const parsed = createSchema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json({ error: "Invalid input" }, { status: 400 });
  }

  const count = await db.habit.count({ where: { userId, archivedAt: null } });
  const habit = await db.habit.create({
    data: { userId, name: parsed.data.name, order: count },
  });

  return NextResponse.json({ habit }, { status: 201 });
}
