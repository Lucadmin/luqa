import { NextResponse } from "next/server";
import { db } from "@/lib/db";
import { syncGoogleHealthSleep } from "@/lib/google-health/sync";

interface GoogleHealthWebhookBody {
  type?: string;
  data?: {
    healthUserId?: string;
    dataType?: string;
    intervals?: Array<{
      physicalTimeInterval?: {
        startTime?: string;
        endTime?: string;
      };
    }>;
  };
}

function notificationRange(body: GoogleHealthWebhookBody): { from: Date; to: Date } {
  const times = (body.data?.intervals ?? [])
    .flatMap((interval) => [
      interval.physicalTimeInterval?.startTime,
      interval.physicalTimeInterval?.endTime,
    ])
    .filter((time): time is string => Boolean(time))
    .map((time) => Date.parse(time))
    .filter((time) => Number.isFinite(time));

  if (times.length === 0) {
    return {
      from: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000),
      to: new Date(Date.now() + 24 * 60 * 60 * 1000),
    };
  }

  return {
    from: new Date(Math.min(...times) - 48 * 60 * 60 * 1000),
    to: new Date(Math.max(...times) + 24 * 60 * 60 * 1000),
  };
}

export async function POST(request: Request) {
  let body: GoogleHealthWebhookBody;
  try {
    body = await request.json();
  } catch {
    return new NextResponse(null, { status: 204 });
  }

  if (body.type === "verification") {
    return new NextResponse(null, { status: 204 });
  }

  if (body.data?.dataType !== "sleep" || !body.data.healthUserId) {
    return new NextResponse(null, { status: 204 });
  }

  const conn = await db.googleHealthConnection.findFirst({
    where: { healthUserId: body.data.healthUserId },
    select: { userId: true },
  });

  if (conn) {
    const range = notificationRange(body);
    await syncGoogleHealthSleep(conn.userId, range).catch((e) =>
      console.error("[google-health-webhook] sleep sync failed", e),
    );
  }

  return new NextResponse(null, { status: 204 });
}
