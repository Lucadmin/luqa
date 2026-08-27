import { NextResponse } from "next/server";
import { getUserId } from "@/lib/api-auth";

// Deprecated. Sleep now arrives from Android Health Connect via the mobile app
// (`POST /api/v1/health/sync`). The route stays so an old client gets a clear
// answer instead of a 404, and so the deprecation is visible in the route tree.
export async function POST() {
  const userId = await getUserId();
  if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  return NextResponse.json(
    {
      error: "Google Health sync is retired",
      detail:
        "Sleep is imported from Android Health Connect by the Luqa mobile app. " +
        "Existing Google Health entries are kept and still readable.",
    },
    { status: 410 },
  );
}
