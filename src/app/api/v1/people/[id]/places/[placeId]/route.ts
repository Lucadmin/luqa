import { mobileJson } from "@/lib/mobile-api-response";
import { moneyRoute, notFound } from "@/lib/server/money-routes";
import { requireOwnedPerson, writeChild } from "@/lib/server/people";

type Params = { params: Promise<{ id: string; placeId: string }> };

export const DELETE = moneyRoute<[Params]>(
  async (session, _request, { params }) => {
    const { id, placeId } = await params;
    if (!(await requireOwnedPerson(session.userId, id))) return notFound();

    const person = await writeChild(id, async (tx) => {
      await tx.personPlace.deleteMany({ where: { id: placeId, personId: id } });
      // Removing the primary leaves the person without one, so the oldest
      // remaining place takes over rather than "where are they" going blank
      // while cities are still on file.
      const remaining = await tx.personPlace.findMany({
        where: { personId: id },
        orderBy: { createdAt: "asc" },
        select: { id: true, isPrimary: true },
      });
      if (remaining.length > 0 && !remaining.some((p) => p.isPrimary)) {
        await tx.personPlace.update({
          where: { id: remaining[0].id },
          data: { isPrimary: true },
        });
      }
    });
    return mobileJson({ person });
  },
);
