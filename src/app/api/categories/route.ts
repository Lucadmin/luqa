import { NextResponse } from "next/server";
import { getUserId } from "@/lib/api-auth";
import { db } from "@/lib/db";
import { toCategoryDTO } from "@/lib/serializers";
import { createCategorySchema } from "@/lib/validations";

// A pleasant default palette, cycled when the user doesn't pick a color.
const PALETTE = [
  "#6366f1", "#ec4899", "#f59e0b", "#10b981", "#3b82f6",
  "#8b5cf6", "#ef4444", "#14b8a6", "#f97316", "#06b6d4",
];

export async function GET() {
  const userId = await getUserId();
  if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const categories = await db.category.findMany({
    where: { userId },
    orderBy: { name: "asc" },
  });

  return NextResponse.json({ categories: categories.map(toCategoryDTO) });
}

export async function POST(request: Request) {
  const userId = await getUserId();
  if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  let body: unknown;
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: "Invalid JSON" }, { status: 400 });
  }

  const parsed = createCategorySchema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json(
      { error: "Invalid input", issues: parsed.error.flatten() },
      { status: 400 },
    );
  }
  const { name, color } = parsed.data;

  // Reuse an existing category with the same name (case-insensitive).
  const existing = await db.category.findFirst({
    where: { userId, name: { equals: name, mode: "insensitive" } },
  });
  if (existing) {
    return NextResponse.json({ category: toCategoryDTO(existing) }, { status: 200 });
  }

  const count = await db.category.count({ where: { userId } });
  const category = await db.category.create({
    data: {
      userId,
      name,
      color: color ?? PALETTE[count % PALETTE.length],
    },
  });

  return NextResponse.json({ category: toCategoryDTO(category) }, { status: 201 });
}
