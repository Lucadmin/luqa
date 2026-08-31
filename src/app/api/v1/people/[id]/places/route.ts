import { invalidInput, invalidJson, mobileJson } from "@/lib/mobile-api-response";
import { moneyRoute, notFound, readJson } from "@/lib/server/money-routes";
import {
  demoteOtherPrimaries,
  requireOwnedPerson,
  writeChild,
} from "@/lib/server/people";
import { personPlaceSchema } from "@/lib/validations";

type Params = { params: Promise<{ id: string }> };

// POST /api/v1/people/[id]/places — a city they can be found in.
//
// City-level and unlocated: geocoding to a city centroid happens separately,
// so a place is usable the moment it is typed and pins once it resolves.
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

    const person = await writeChild(id, async (tx) => {
      const count = await tx.personPlace.count({ where: { personId: id } });
      // The first place is primary whether or not anybody asked: a person with
      // exactly one city and no primary has no answer to "where are they".
      const isPrimary = d.isPrimary || count === 0;

      const place = d.id
        ? await tx.personPlace.upsert({
            where: { id: d.id },
            create: {
              id: d.id,
              personId: id,
              label: d.label,
              city: d.city,
              region: d.region ?? null,
              country: d.country ?? null,
              address: d.address ?? null,
              isPrimary,
            },
            update: {},
          })
        : await tx.personPlace.create({
            data: {
              personId: id,
              label: d.label,
              city: d.city,
              region: d.region ?? null,
              country: d.country ?? null,
              address: d.address ?? null,
              isPrimary,
            },
          });

      if (isPrimary) await demoteOtherPrimaries(tx, id, place.id);
    });
    return mobileJson({ person });
  },
);
