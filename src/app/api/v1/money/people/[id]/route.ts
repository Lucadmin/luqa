import type { Prisma } from "@/generated/prisma/client";
import { db } from "@/lib/db";
import {
  invalidInput,
  invalidJson,
  mobileJson,
} from "@/lib/mobile-api-response";
import { toPersonDTO } from "@/lib/serializers";
import {
  moneyRoute,
  notFound,
  readJson,
  rejected,
} from "@/lib/server/money-routes";
import { updatePersonSchema } from "@/lib/validations";

type Params = { params: Promise<{ id: string }> };

// PATCH /api/v1/money/people/[id] — rename, restyle, change the default cut,
// reorder, archive or restore.
export const PATCH = moneyRoute<[Params]>(
  async (session, request, { params }) => {
    const { id } = await params;
    const existing = await db.person.findFirst({
      where: { id, userId: session.userId },
    });
    if (!existing) return notFound();

    let body: unknown;
    try {
      body = await readJson(request);
    } catch {
      return invalidJson();
    }
    const parsed = updatePersonSchema.safeParse(body);
    if (!parsed.success) return invalidInput(parsed.error.flatten());
    const d = parsed.data;

    if (d.name !== undefined && d.name !== existing.name) {
      const taken = await db.person.findFirst({
        where: { userId: session.userId, name: d.name, id: { not: id } },
        select: { id: true },
      });
      if (taken) return rejected(`You already have someone called ${d.name}`);
    }

    const data: Prisma.PersonUpdateInput = {};
    if (d.name !== undefined) data.name = d.name;
    if (d.color !== undefined) data.color = d.color;
    if (d.emoji !== undefined) data.emoji = d.emoji ?? null;
    if (d.defaultPercent !== undefined) {
      data.defaultPercent = d.defaultPercent ?? null;
    }
    if (d.order !== undefined) data.order = d.order;
    if (d.archived !== undefined) {
      data.archivedAt = d.archived ? new Date() : null;
    }

    const person = await db.person.update({ where: { id }, data });
    return mobileJson({ person: toPersonDTO(person) });
  },
);

// DELETE /api/v1/money/people/[id] — remove someone.
//
// Anyone who has been on a bill is archived rather than deleted, so the
// history that produced their balance survives. Someone added by mistake, with
// nothing attached, is removed outright. `deleted` says which happened, so the
// client knows whether to expect the row back.
export const DELETE = moneyRoute<[Params]>(
  async (session, _request, { params }) => {
    const { id } = await params;
    const person = await db.person.findFirst({
      where: { id, userId: session.userId },
    });
    // Already gone: a delete replayed from a phone's queue must not fail on
    // its second attempt.
    if (!person) return mobileJson({ deleted: true });

    const [shares, paid, settlements] = await Promise.all([
      db.expenseShare.count({ where: { personId: id } }),
      db.expense.count({ where: { paidByPersonId: id } }),
      db.settlement.count({ where: { personId: id } }),
    ]);

    if (shares + paid + settlements === 0) {
      await db.person.delete({ where: { id } });
      return mobileJson({ deleted: true });
    }

    await db.person.update({ where: { id }, data: { archivedAt: new Date() } });
    return mobileJson({ deleted: false });
  },
);
