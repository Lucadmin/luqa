import type { Prisma } from "@/generated/prisma/client";
import { db } from "@/lib/db";
import { invalidInput, invalidJson, mobileJson } from "@/lib/mobile-api-response";
import { toPersonDTO } from "@/lib/serializers";
import {
  moneyRoute,
  notFound,
  readJson,
  rejected,
} from "@/lib/server/money-routes";
import {
  deletePerson,
  findPerson,
  profileUpdateData,
  updatePersonRow,
} from "@/lib/server/people";
import { updatePersonSchema } from "@/lib/validations";

type Params = { params: Promise<{ id: string }> };

// GET /api/v1/people/[id] — one person, whole profile.
export const GET = moneyRoute<[Params]>(async (session, _request, { params }) => {
  const { id } = await params;
  const person = await findPerson(session.userId, id);
  if (!person) return notFound();
  return mobileJson({ person: toPersonDTO(person) });
});

// PATCH /api/v1/people/[id] — identity and profile in one write.
//
// The same endpoint Money's split-defaults editor uses, because a rename is a
// rename whichever screen it was typed on.
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

    const data: Prisma.PersonUpdateInput = { ...profileUpdateData(d) };
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

    return mobileJson({ person: await updatePersonRow(id, data) });
  },
);

// DELETE /api/v1/people/[id] — remove someone.
//
// The rules live in the people service, shared with the money contract, so the
// two can never disagree about what "remove" means.
export const DELETE = moneyRoute<[Params]>(
  async (session, _request, { params }) => {
    const { id } = await params;
    const result = await deletePerson(session.userId, id);
    return result.kind === "gone"
      ? mobileJson({ deleted: true })
      : mobileJson({ deleted: false, person: result.person });
  },
);
