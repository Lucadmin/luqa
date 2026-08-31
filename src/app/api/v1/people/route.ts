import { invalidInput, invalidJson, mobileJson } from "@/lib/mobile-api-response";
import { createMobilePersonSchema } from "@/lib/mobile-api-validation";
import { moneyRoute, readJson } from "@/lib/server/money-routes";
import { createPerson, listPeople } from "@/lib/server/people";

// GET /api/v1/people — everyone, archived included, in display order, each
// with their whole profile. The People tab's only read.
export const GET = moneyRoute(async (session) =>
  mobileJson({ people: await listPeople(session.userId) }),
);

// POST /api/v1/people — add someone, profile and all.
//
// The convergence rules live in the people service and are shared with the
// money contract, so a person added from either screen behaves identically.
export const POST = moneyRoute(async (session, request) => {
  let body: unknown;
  try {
    body = await readJson(request);
  } catch {
    return invalidJson();
  }
  const parsed = createMobilePersonSchema.safeParse(body);
  if (!parsed.success) return invalidInput(parsed.error.flatten());

  const { person, created } = await createPerson(session.userId, parsed.data);
  return mobileJson({ person }, { status: created ? 201 : 200 });
});
