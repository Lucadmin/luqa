import { mobileJson } from "@/lib/mobile-api-response";
import { moneyOverview } from "@/lib/server/money";
import { moneyRoute } from "@/lib/server/money-routes";

// GET /api/v1/money — the whole money tab in one payload: every balance, the
// groups, and the headline totals. Bills are paginated separately so the feed
// can keep loading without re-sending the balances.
export const GET = moneyRoute(async (session) =>
  mobileJson({ overview: await moneyOverview(session.userId) }),
);
