import { db } from "@/lib/db";
import { invalidInput, invalidJson, mobileJson } from "@/lib/mobile-api-response";
import { moneyRoute, notFound, readJson } from "@/lib/server/money-routes";
import { requireOwnedPerson, writeChild } from "@/lib/server/people";
import { updatePersonGiftSchema } from "@/lib/validations";

type Params = { params: Promise<{ id: string; giftId: string }> };

// PATCH — reword it, or mark it given. `givenAt: null` puts it back on the
// list; a date takes it off. Either way the row stays, because the list's
// second job is not giving the same thing twice.
export const PATCH = moneyRoute<[Params]>(
  async (session, request, { params }) => {
    const { id, giftId } = await params;
    if (!(await requireOwnedPerson(session.userId, id))) return notFound();

    let body: unknown;
    try {
      body = await readJson(request);
    } catch {
      return invalidJson();
    }
    const parsed = updatePersonGiftSchema.safeParse(body);
    if (!parsed.success) return invalidInput(parsed.error.flatten());
    const d = parsed.data;

    const existing = await db.personGiftIdea.findFirst({
      where: { id: giftId, personId: id },
      select: { id: true },
    });
    if (!existing) return notFound();

    const person = await writeChild(id, (tx) =>
      tx.personGiftIdea.update({
        where: { id: giftId },
        data: {
          ...(d.idea !== undefined ? { idea: d.idea } : {}),
          ...(d.url !== undefined ? { url: d.url ?? null } : {}),
          ...(d.givenAt !== undefined
            ? { givenAt: d.givenAt ? new Date(d.givenAt) : null }
            : {}),
        },
      }),
    );
    return mobileJson({ person });
  },
);

export const DELETE = moneyRoute<[Params]>(
  async (session, _request, { params }) => {
    const { id, giftId } = await params;
    if (!(await requireOwnedPerson(session.userId, id))) return notFound();

    const person = await writeChild(id, (tx) =>
      tx.personGiftIdea.deleteMany({ where: { id: giftId, personId: id } }),
    );
    return mobileJson({ person });
  },
);
