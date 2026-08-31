import { NextResponse } from "next/server";
import { getUserId } from "@/lib/api-auth";
import {
  InvalidCategoryError,
  createTimeEntry,
  listTimeEntries,
  parseEntryWindow,
} from "@/lib/server/today";
import { createEntrySchema } from "@/lib/validations";

// GET /api/entries?from=ISO&to=ISO
// Returns entries overlapping [from, to), plus any still-running entry.
export async function GET(request: Request) {
  const userId = await getUserId();
  if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const window = parseEntryWindow(new URL(request.url).searchParams);
  if (!window.ok) {
    return NextResponse.json({ error: window.message }, { status: 400 });
  }
  return NextResponse.json({ entries: await listTimeEntries(userId, window) });
}

// POST /api/entries — create an entry (past block or a running timer).
export async function POST(request: Request) {
  const userId = await getUserId();
  if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  let body: unknown;
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: "Invalid JSON" }, { status: 400 });
  }

  const parsed = createEntrySchema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json(
      { error: "Invalid input", issues: parsed.error.flatten() },
      { status: 400 },
    );
  }
  try {
    const result = await createTimeEntry(userId, parsed.data);
    return NextResponse.json(
      { entry: result.entry },
      { status: result.created ? 201 : 200 },
    );
  } catch (error) {
    if (error instanceof InvalidCategoryError) {
      return NextResponse.json({ error: "Unknown category" }, { status: 400 });
    }
    throw error;
  }
}
