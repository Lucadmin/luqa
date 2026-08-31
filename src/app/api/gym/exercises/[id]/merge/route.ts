import { NextResponse } from "next/server";
import { getUserId } from "@/lib/api-auth";
import { mergeExercises } from "@/lib/server/gym";
import { mergeExerciseSchema } from "@/lib/validations";

export async function POST(
  request: Request,
  { params }: { params: Promise<{ id: string }> },
) {
  const userId = await getUserId();
  if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const { id } = await params;
  let body: unknown;
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: "Invalid JSON" }, { status: 400 });
  }

  const parsed = mergeExerciseSchema.safeParse(body);
  if (!parsed.success || parsed.data.targetExerciseId === id) {
    return NextResponse.json(
      { error: "Choose a different target exercise" },
      { status: 400 },
    );
  }

  const result = await mergeExercises(userId, id, parsed.data.targetExerciseId);
  if (!result) return NextResponse.json({ error: "Not found" }, { status: 404 });

  return NextResponse.json({
    exercise: result.exercise,
    mergedExerciseId: id,
    movedEntries: result.movedEntries,
  });
}
