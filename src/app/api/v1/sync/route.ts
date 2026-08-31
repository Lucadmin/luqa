import { mobileAuthError, mobileJson } from "@/lib/mobile-api-response";
import { authenticateMobileRequest } from "@/lib/server/mobile-auth";
import {
  decodeSyncCursor,
  parseCollections,
  syncDelta,
  syncLimitFrom,
  syncSettings,
  type SyncCollection,
} from "@/lib/server/sync";

// GET /api/v1/sync — everything about this account that changed since the
// cursors the caller holds.
//
// Cursors are per collection and are passed as `cursor.<name>`, e.g.
// `?cursor.expenses=<token>&cursor.people=<token>`. Omitting one asks for that
// collection from the beginning, which is what a fresh install does.
//
// `?collections=people,expenses` narrows the answer; the default is all of
// them. `?limit=` caps rows per collection per request; a collection that hits
// the cap says `hasMore` and is asked again with the cursor it returned.
export async function GET(request: Request) {
  try {
    const session = await authenticateMobileRequest(request);
    const url = new URL(request.url);

    const collections = parseCollections(url.searchParams.get("collections"));
    const limit = syncLimitFrom(url.searchParams.get("limit"));

    const cursors: Partial<
      Record<SyncCollection, ReturnType<typeof decodeSyncCursor>>
    > = {};
    for (const name of collections) {
      // A cursor that cannot be read is treated as no cursor rather than as an
      // error: the collection resyncs from the start, which is slow but always
      // correct, where refusing would leave the device permanently stuck.
      cursors[name] = decodeSyncCursor(
        url.searchParams.get(`cursor.${name}`),
      );
    }

    const [settings, delta] = await Promise.all([
      syncSettings(session.userId),
      syncDelta(session.userId, collections, cursors, limit),
    ]);
    return mobileJson({ settings, collections: delta });
  } catch (error) {
    const response = mobileAuthError(error);
    if (response) return response;
    throw error;
  }
}
