import { NextResponse } from "next/server";
import { getUserId } from "@/lib/api-auth";
import { syncGoogleHealthSleep } from "@/lib/google-health/sync";

export async function POST(request: Request) {
  const userId = await getUserId();
  if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const { searchParams } = new URL(request.url);
  const from = searchParams.get("from");
  const to = searchParams.get("to");
  const fromDate = from ? new Date(from) : undefined;
  const toDate = to ? new Date(to) : undefined;

  if (
    (fromDate && Number.isNaN(fromDate.getTime())) ||
    (toDate && Number.isNaN(toDate.getTime()))
  ) {
    return NextResponse.json({ error: "Invalid from/to" }, { status: 400 });
  }

  const result = await syncGoogleHealthSleep(userId, {
    from: fromDate,
    to: toDate,
  });

  return NextResponse.json(result);
}
