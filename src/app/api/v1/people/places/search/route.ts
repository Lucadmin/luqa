import { mobileJson } from "@/lib/mobile-api-response";
import { moneyRoute } from "@/lib/server/money-routes";
import { searchCities, SEARCH_LIMIT } from "@/lib/server/geocode";

// GET /api/v1/people/places/search?q= — the cities a name might mean.
//
// So that the owner decides which Springfield, rather than a geocoder deciding
// for them. Each candidate carries its administrative area, its country and
// its population, which is what makes two rows reading "Springfield"
// distinguishable, and a stable id, which is what the chosen place stores.
//
// Answering also fills the shared city cache, so adding the place afterwards
// resolves that id from the database and never touches the network.
export const GET = moneyRoute(async (_session, request) => {
  const url = new URL(request.url);
  const query = url.searchParams.get("q") ?? "";
  const requested = Number(url.searchParams.get("limit"));
  const limit =
    Number.isInteger(requested) && requested > 0
      ? Math.min(requested, SEARCH_LIMIT)
      : SEARCH_LIMIT;

  // A query too short to be a city name answers with nothing rather than with
  // everything: `searchCities` holds that rule, so the batch geocoder obeys it
  // too.
  return mobileJson({ results: await searchCities(query, limit) });
});
