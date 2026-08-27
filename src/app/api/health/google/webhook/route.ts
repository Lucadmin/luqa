import { NextResponse } from "next/server";
import { db } from "@/lib/db";
import {
  bearerToken,
  verifyOptionalWebhookToken,
} from "@/lib/webhook-security";

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

export async function POST(request: Request) {
  const url = new URL(request.url);
  const token =
    bearerToken(request.headers.get("authorization")) ||
    request.headers.get("x-luqa-webhook-token") ||
    url.searchParams.get("token");

  if (!verifyOptionalWebhookToken("GOOGLE_HEALTH_WEBHOOK_TOKEN", token)) {
    return new NextResponse(null, { status: 401 });
  }

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

  // Deprecated: acknowledged but no longer acted on. Sleep is imported from
  // Health Connect on the phone, so a Google-side change notification has
  // nothing to trigger. Google keeps retrying anything that is not a 2xx, hence
  // the 204 rather than a 410.
  const conn = await db.googleHealthConnection.findFirst({
    where: { healthUserId: body.data.healthUserId },
    select: { userId: true },
  });
  if (conn) {
    console.info(
      "[google-health-webhook] ignoring notification; Health Connect is the sleep source now",
    );
  }

  return new NextResponse(null, { status: 204 });
}
