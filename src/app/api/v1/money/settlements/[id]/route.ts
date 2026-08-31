import { db } from "@/lib/db";
import {
  invalidInput,
  invalidJson,
  mobileJson,
} from "@/lib/mobile-api-response";
import { toSettlementDTO } from "@/lib/serializers";
import { dateFromKey } from "@/lib/server/money";
import { moneyRoute, notFound, readJson } from "@/lib/server/money-routes";
import { updateSettlementSchema } from "@/lib/validations";

type Params = { params: Promise<{ id: string }> };

// PATCH /api/v1/money/settlements/[id] — correct a payback.
export const PATCH = moneyRoute<[Params]>(
  async (session, request, { params }) => {
    const { id } = await params;
    const existing = await db.settlement.findFirst({
      where: { id, userId: session.userId },
    });
    if (!existing) return notFound();

    let body: unknown;
    try {
      body = await readJson(request);
    } catch {
      return invalidJson();
    }
    const parsed = updateSettlementSchema.safeParse(body);
    if (!parsed.success) return invalidInput(parsed.error.flatten());
    const d = parsed.data;

    const settlement = await db.settlement.update({
      where: { id },
      data: {
        ...(d.amountCents !== undefined ? { amountCents: d.amountCents } : {}),
        ...(d.direction !== undefined ? { direction: d.direction } : {}),
        ...(d.date !== undefined ? { date: dateFromKey(d.date) } : {}),
        ...(d.notes !== undefined ? { notes: d.notes } : {}),
      },
    });

    return mobileJson({ settlement: toSettlementDTO(settlement) });
  },
);

// DELETE /api/v1/money/settlements/[id] — undo a payback.
export const DELETE = moneyRoute<[Params]>(
  async (session, _request, { params }) => {
    const { id } = await params;
    await db.settlement.deleteMany({ where: { id, userId: session.userId } });
    return new Response(null, { status: 204 });
  },
);
