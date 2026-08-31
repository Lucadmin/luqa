import { invalidInput, invalidJson, mobileJson } from "@/lib/mobile-api-response";
import { moneyRoute, notFound, readJson } from "@/lib/server/money-routes";
import { markSeen, requireOwnedPerson } from "@/lib/server/people";
import { markSeenSchema } from "@/lib/validations";

type Params = { params: Promise<{ id: string }> };

// POST /api/v1/people/[id]/seen — record that they were actually seen.
//
// Its own endpoint rather than a PATCH field: it is the write the person
// screen makes most often, and it carries a rule a general update does not —
// a "saw them on Tuesday" replayed from a phone's queue on Friday must not
// drag the date back past a sighting already recorded since.
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
    const parsed = markSeenSchema.safeParse(body ?? {});
    if (!parsed.success) return invalidInput(parsed.error.flatten());

    const when = parsed.data.seenAt ? new Date(parsed.data.seenAt) : new Date();
    return mobileJson({ person: await markSeen(id, when) });
  },
);
