import { NextResponse } from "next/server";
import { getUserId } from "@/lib/api-auth";
import { db } from "@/lib/db";
import { importSleepEntries } from "@/lib/sleep";
import { toSleepDTO } from "@/lib/serializers";
import { importSleepSchema } from "@/lib/validations";

// GET /api/sleep?from=ISO&to=ISO
// Returns sleep sessions whose wake time falls inside [from, to).
export async function GET(request: Request) {
  const userId = await getUserId();
  if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const { searchParams } = new URL(request.url);
  const from = searchParams.get("from");
  const to = searchParams.get("to");
  if (!from || !to) {
    return NextResponse.json({ error: "from and to are required" }, { status: 400 });
  }

  const fromDate = new Date(from);
  const toDate = new Date(to);
  if (Number.isNaN(fromDate.getTime()) || Number.isNaN(toDate.getTime())) {
    return NextResponse.json({ error: "Invalid from/to" }, { status: 400 });
  }

  const entries = await db.sleepEntry.findMany({
    where: {
      userId,
      deletedAt: null,
      endTime: { gte: fromDate, lt: toDate },
    },
    orderBy: { endTime: "asc" },
  });

  return NextResponse.json({ entries: entries.map(toSleepDTO) });
}

// POST /api/sleep
// Imports provider sleep sessions. Idempotent by (user, source, externalId).
export async function POST(request: Request) {
  const userId = await getUserId();
  if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  let body: unknown;
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: "Invalid JSON" }, { status: 400 });
  }

  const parsed = importSleepSchema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json(
      { error: "Invalid input", issues: parsed.error.flatten() },
      { status: 400 },
    );
  }

  const result = await importSleepEntries(userId, parsed.data);
  return NextResponse.json(result);
}
