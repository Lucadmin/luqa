import { NextResponse } from "next/server";
import { getUserId } from "@/lib/api-auth";
import { db } from "@/lib/db";
import { toGymLocationDTO } from "@/lib/serializers";
import { createGymLocationSchema } from "@/lib/validations";

// GET /api/gym/locations
export async function GET() {
  const userId = await getUserId();
  if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const locations = await db.gymLocation.findMany({
    where: { userId },
    orderBy: [{ order: "asc" }, { code: "asc" }],
  });

  return NextResponse.json({ locations: locations.map(toGymLocationDTO) });
}

// POST /api/gym/locations — a short code plus what it stands for.
export async function POST(request: Request) {
  const userId = await getUserId();
  if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  let body: unknown;
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: "Invalid JSON" }, { status: 400 });
  }

  const parsed = createGymLocationSchema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json(
      { error: "Invalid input", issues: parsed.error.flatten() },
      { status: 400 },
    );
  }
  const d = parsed.data;

  const existing = await db.gymLocation.findFirst({
    where: { userId, code: d.code },
    select: { id: true },
  });
  if (existing) {
    return NextResponse.json({ error: "That code is already taken" }, { status: 409 });
  }

  const count = await db.gymLocation.count({ where: { userId } });

  const location = await db.gymLocation.create({
    data: {
      userId,
      code: d.code,
      name: d.name,
      ...(d.color ? { color: d.color } : {}),
      order: count,
    },
  });

  return NextResponse.json({ location: toGymLocationDTO(location) }, { status: 201 });
}
