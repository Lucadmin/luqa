import { mobileJson } from "@/lib/mobile-api-response";
import { personLedger } from "@/lib/server/money";
import { moneyRoute, notFound } from "@/lib/server/money-routes";

type Params = { params: Promise<{ id: string }> };

// GET /api/v1/money/people/[id]/ledger — one person's whole history with the
// user, plus the balance and treat totals it adds up to.
export const GET = moneyRoute<[Params]>(
  async (session, _request, { params }) => {
    const { id } = await params;
    const ledger = await personLedger(session.userId, id);
    if (!ledger) return notFound();
    return mobileJson({ ledger });
  },
);
