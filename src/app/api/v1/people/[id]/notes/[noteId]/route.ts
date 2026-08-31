import { invalidInput, invalidJson, mobileJson } from "@/lib/mobile-api-response";
import { db } from "@/lib/db";
import { moneyRoute, notFound, readJson } from "@/lib/server/money-routes";
import { requireOwnedPerson, writeChild } from "@/lib/server/people";
import { updatePersonNoteSchema } from "@/lib/validations";

type Params = { params: Promise<{ id: string; noteId: string }> };

export const PATCH = moneyRoute<[Params]>(
  async (session, request, { params }) => {
    const { id, noteId } = await params;
    if (!(await requireOwnedPerson(session.userId, id))) return notFound();

    let body: unknown;
    try {
      body = await readJson(request);
    } catch {
      return invalidJson();
    }
    const parsed = updatePersonNoteSchema.safeParse(body);
    if (!parsed.success) return invalidInput(parsed.error.flatten());
    const d = parsed.data;

    // Scoped to the person as well as the note, so an id from one person's
    // queue cannot edit another person's note.
    const existing = await db.personNote.findFirst({
      where: { id: noteId, personId: id },
      select: { id: true },
    });
    if (!existing) return notFound();

    const person = await writeChild(id, (tx) =>
      tx.personNote.update({
        where: { id: noteId },
        data: {
          ...(d.body !== undefined ? { body: d.body } : {}),
          ...(d.pinned !== undefined ? { pinned: d.pinned } : {}),
          ...(d.happenedOn !== undefined
            ? { happenedOn: d.happenedOn ?? null }
            : {}),
        },
      }),
    );
    return mobileJson({ person });
  },
);

export const DELETE = moneyRoute<[Params]>(
  async (session, _request, { params }) => {
    const { id, noteId } = await params;
    if (!(await requireOwnedPerson(session.userId, id))) return notFound();

    const person = await writeChild(id, (tx) =>
      // deleteMany rather than delete: a removal replayed from a queue finds
      // nothing the second time, and that is success, not a 500.
      tx.personNote.deleteMany({ where: { id: noteId, personId: id } }),
    );
    return mobileJson({ person });
  },
);
