import { invalidInput, invalidJson, mobileJson } from "@/lib/mobile-api-response";
import { moneyRoute, notFound, readJson } from "@/lib/server/money-routes";
import { requireOwnedPerson, writeChild } from "@/lib/server/people";
import { personGiftSchema } from "@/lib/validations";

type Params = { params: Promise<{ id: string }> };

// POST /api/v1/people/[id]/gifts — something to give them.
export const POST = moneyRoute<[Params]>(
  async (session, request, { params }) => {
    const { id } = await params;
    if (!(await requireOwnedPerson(session.userId, id))) return notFound();

    let body: unknown;
    try {
      body = await readJson(request);
    } catch {
      return invalidJson();
    }
    const parsed = personGiftSchema.safeParse(body);
    if (!parsed.success) return invalidInput(parsed.error.flatten());
    const d = parsed.data;

    const person = await writeChild(id, async (tx) => {
      if (d.id) {
        await tx.personGiftIdea.upsert({
          where: { id: d.id },
          create: {
            id: d.id,
            personId: id,
            idea: d.idea,
            url: d.url ?? null,
          },
          update: {},
        });
        return;
      }
      await tx.personGiftIdea.create({
        data: { personId: id, idea: d.idea, url: d.url ?? null },
      });
    });
    return mobileJson({ person });
  },
);
