import { NextResponse } from "next/server";
import { getUserId } from "@/lib/api-auth";
import { createCategory, listCategories } from "@/lib/server/today";
import { createCategorySchema } from "@/lib/validations";

export async function GET() {
  const userId = await getUserId();
  if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  return NextResponse.json({ categories: await listCategories(userId) });
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
  const result = await createCategory(userId, parsed.data);
  return NextResponse.json(
    { category: result.category },
    { status: result.created ? 201 : 200 },
  );
}
