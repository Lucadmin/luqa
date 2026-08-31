import type { Prisma } from "@/generated/prisma/client";
import { db } from "@/lib/db";
import {
  invalidInput,
  invalidJson,
  mobileJson,
} from "@/lib/mobile-api-response";
import { toPersonDTO } from "@/lib/serializers";
import { deletePerson, personInclude } from "@/lib/server/people";
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

    const person = await db.person.update({
      where: { id },
      data,
      include: personInclude,
    });
    return mobileJson({ person: toPersonDTO(person) });
  },
);

// DELETE /api/v1/money/people/[id] — remove someone.
//
// Shares its rules with `/v1/people/[id]`: anyone who has been on a bill is
// archived so the history that produced everyone else's balances survives,
// and someone with nothing attached is tombstoned. One implementation, so the
// two contracts cannot come to disagree about what "remove" means.
export const DELETE = moneyRoute<[Params]>(
  async (session, _request, { params }) => {
    const { id } = await params;
    const result = await deletePerson(session.userId, id);
    return mobileJson({ deleted: result.kind === "gone" });
  },
);
