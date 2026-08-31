import {
  invalidInput,
  invalidJson,
  mobileAuthError,
  mobileJson,
  readJson,
} from "@/lib/mobile-api-response";
import { mergeExercises } from "@/lib/server/gym";
import { authenticateMobileRequest } from "@/lib/server/mobile-auth";
import { mergeExerciseSchema } from "@/lib/validations";

export async function POST(
  request: Request,
  { params }: { params: Promise<{ id: string }> },
) {
  let mobileSession;
  try {
    mobileSession = await authenticateMobileRequest(request);
  } catch (error) {
    const response = mobileAuthError(error);
    if (response) return response;
    throw error;
  }

  const { id } = await params;
  let body: unknown;
  try {
    body = await readJson(request);
  } catch {
    return invalidJson();
  }

  const parsed = mergeExerciseSchema.safeParse(body);
  if (!parsed.success) return invalidInput(parsed.error.flatten());
  if (parsed.data.targetExerciseId === id) {
    return mobileJson(
      {
        error: {
          code: "same_exercise",
          message: "Choose a different target exercise",
        },
      },
      { status: 400 },
    );
  }

  const result = await mergeExercises(
    mobileSession.userId,
    id,
    parsed.data.targetExerciseId,
  );
  if (!result) {
    return mobileJson(
      { error: { code: "not_found", message: "Exercise not found" } },
      { status: 404 },
    );
  }

  return mobileJson({
    exercise: result.exercise,
    mergedExerciseId: id,
    movedEntries: result.movedEntries,
  });
}
