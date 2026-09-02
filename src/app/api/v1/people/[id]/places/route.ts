import {
  invalidInput,
  invalidJson,
  mobileJson,
} from "@/lib/mobile-api-response";
import { moneyRoute, notFound, readJson } from "@/lib/server/money-routes";
import { placeWriteData } from "@/lib/person-profile";
import { resolveCityId } from "@/lib/server/geocode";
import {
  demoteOtherPrimaries,
  requireOwnedPerson,
  writeChild,
} from "@/lib/server/people";
import { personPlaceSchema } from "@/lib/validations";

type Params = { params: Promise<{ id: string }> };

// POST /api/v1/people/[id]/places — a city they can be found in.
//
// Two ways in, and the difference is whether anybody chose. A request carrying
// `cityId` picked a city from the search list, so the point is written here
// and the place pins immediately; the id resolves from the shared city cache
// that the search itself filled, so this costs a primary-key read rather than
// a call to a third party. A request without one is a name that was only typed
// — offline, or imported from a contact book — and it lands unlocated for the
// geocoding batch to guess at later.
//
// City-level either way. Only a centroid is ever stored, which answers "who is
// in this city" exactly as well as a street address would, without turning a
// record of friends' addresses into a map of their front doors.
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
    const parsed = personPlaceSchema.safeParse(body);
    if (!parsed.success) return invalidInput(parsed.error.flatten());
    const d = parsed.data;

    // An id the cache has never heard of — one held by a client for longer
    // than the row survived, say — is not a reason to refuse the write. It
    // resolves to null and the place falls back to being a typed name, which
    // is a state that already sorts itself out.
    const chosen = d.cityId ? await resolveCityId(d.cityId) : null;
    const data = placeWriteData(d, chosen);

    const person = await writeChild(id, async (tx) => {
      const count = await tx.personPlace.count({ where: { personId: id } });
      // The first place is primary whether or not anybody asked: a person with
      // exactly one city and no primary has no answer to "where are they".
      const isPrimary = d.isPrimary || count === 0;

      const place = d.id
        ? await tx.personPlace.upsert({
            where: { id: d.id },
            create: { id: d.id, personId: id, ...data, isPrimary },
            update: {},
          })
        : await tx.personPlace.create({
            data: { personId: id, ...data, isPrimary },
          });

      if (isPrimary) await demoteOtherPrimaries(tx, id, place.id);
    });
    return mobileJson({ person });
  },
);
