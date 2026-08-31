import { invalidInput, invalidJson, mobileJson } from "@/lib/mobile-api-response";
import { moneyRoute, notFound, readJson } from "@/lib/server/money-routes";
import { requireOwnedPerson, writeChild } from "@/lib/server/people";
import { personNoteSchema } from "@/lib/validations";

type Params = { params: Promise<{ id: string }> };

// POST /api/v1/people/[id]/notes — write something down about them.
//
// Answers with the whole person rather than the note: one row is one profile,
// so the client replaces what it has instead of splicing a child into it.
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
    const parsed = personNoteSchema.safeParse(body);
    if (!parsed.success) return invalidInput(parsed.error.flatten());
    const d = parsed.data;

    const person = await writeChild(id, async (tx) => {
      // The phone names the row, so a retry after a lost response writes the
      // note once rather than twice.
      if (d.id) {
        await tx.personNote.upsert({
          where: { id: d.id },
          create: {
            id: d.id,
            personId: id,
            body: d.body,
            pinned: d.pinned,
            happenedOn: d.happenedOn ?? null,
          },
          update: {},
        });
        return;
      }
      await tx.personNote.create({
        data: {
          personId: id,
          body: d.body,
          pinned: d.pinned,
          happenedOn: d.happenedOn ?? null,
        },
      });
    });
    return mobileJson({ person });
  },
);
