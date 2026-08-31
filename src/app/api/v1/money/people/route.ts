import {
  invalidInput,
  invalidJson,
  mobileJson,
} from "@/lib/mobile-api-response";
import { createMobilePersonSchema } from "@/lib/mobile-api-validation";
import { createPerson, listPeople } from "@/lib/server/people";
import { moneyRoute, readJson } from "@/lib/server/money-routes";

// GET /api/v1/money/people — everyone, archived included, in display order.
export const GET = moneyRoute(async (session) => {
  // The same rows the People contract serves, profile included: two endpoints
  // returning different shapes for one row is how a client ends up believing
  // somebody has no notes.
  return mobileJson({ people: await listPeople(session.userId) });
});

// POST /api/v1/money/people — add someone to split with.
//
// Delegates to the same service `/v1/people` uses: the convergence rules that
// keep an offline "Mira" from becoming two people are not worth having two
// copies of.
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
