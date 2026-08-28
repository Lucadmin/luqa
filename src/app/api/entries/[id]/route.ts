import { NextResponse } from "next/server";
import { getUserId } from "@/lib/api-auth";
import {
  EntryRangeError,
  InvalidCategoryError,
  deleteTimeEntry,
  updateTimeEntry,
} from "@/lib/server/today";
import { updateEntrySchema } from "@/lib/validations";

type Params = { params: Promise<{ id: string }> };

// PATCH /api/entries/:id — edit description, category, or times.
export async function PATCH(request: Request, { params }: Params) {
  const userId = await getUserId();
  if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const { id } = await params;

  let body: unknown;
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: "Invalid JSON" }, { status: 400 });
  }

  const parsed = updateEntrySchema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json(
      { error: "Invalid input", issues: parsed.error.flatten() },
      { status: 400 },
    );
  }

  try {
    const entry = await updateTimeEntry(userId, id, parsed.data);
    if (!entry) return NextResponse.json({ error: "Not found" }, { status: 404 });
    return NextResponse.json({ entry });
  } catch (error) {
    if (error instanceof InvalidCategoryError) {
      return NextResponse.json({ error: "Unknown category" }, { status: 400 });
    }
    if (error instanceof EntryRangeError) {
      return NextResponse.json({ error: error.message }, { status: 400 });
    }
    throw error;
  }
}

// DELETE /api/entries/:id — soft delete + propagate to Google Calendar.
export async function DELETE(_request: Request, { params }: Params) {
  const userId = await getUserId();
  if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const { id } = await params;
  const deleted = await deleteTimeEntry(userId, id);
  if (!deleted) return NextResponse.json({ error: "Not found" }, { status: 404 });

  return NextResponse.json({ ok: true });
}
