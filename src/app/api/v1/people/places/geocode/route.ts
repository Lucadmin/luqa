import { mobileJson } from "@/lib/mobile-api-response";
import { moneyRoute } from "@/lib/server/money-routes";
import { geocodePendingPlaces } from "@/lib/server/geocode";

// POST /api/v1/people/places/geocode — put points on the cities that have none.
//
// Pull rather than push. Adding a city answers instantly and the pin catches
// up: geocoding on the write path would make typing "Munich" wait on a
// rate-limited third party, and a serverless request cannot promise to finish
// background work after it has replied.
//
// The client calls this when it opens the map, and again while `remaining` is
// above zero.
export const POST = moneyRoute(async (session) =>
  mobileJson(await geocodePendingPlaces(session.userId)),
);
