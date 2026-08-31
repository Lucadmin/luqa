import {
  mobileAuthError,
  mobileJson,
  readJson,
} from "@/lib/mobile-api-response";
import {
  authenticateMobileRequest,
  type AuthenticatedMobileSession,
} from "@/lib/server/mobile-auth";
import { MoneyIdConflictError } from "@/lib/server/money";

/**
 * The boilerplate every money route on the mobile contract repeats: prove the
 * bearer token, read the body when there is one, and turn the two failures
 * either of those can produce into the contract's error shape.
 *
 * Written as a wrapper rather than a snippet per route because the money
 * surface is a dozen handlers wide, and a single one that forgets to answer
 * 401 in the contract's shape is a client that cannot tell "signed out" from
 * "broken".
 */
export function moneyRoute<Args extends unknown[]>(
  handler: (
    session: AuthenticatedMobileSession,
    request: Request,
    ...args: Args
  ) => Promise<Response>,
): (request: Request, ...args: Args) => Promise<Response> {
  return async (request, ...args) => {
    let session: AuthenticatedMobileSession;
    try {
      session = await authenticateMobileRequest(request);
    } catch (error) {
      const response = mobileAuthError(error);
      if (response) return response;
      throw error;
    }

    try {
      return await handler(session, request, ...args);
    } catch (error) {
      if (error instanceof MoneyIdConflictError) {
        return mobileJson(
          { error: { code: "id_conflict", message: error.message } },
          { status: 409 },
        );
      }
      throw error;
    }
  };
}

/** A refusal the client can show verbatim — an unknown person, a bad split. */
export function rejected(message: string, code = "invalid_input") {
  return mobileJson({ error: { code, message } }, { status: 400 });
}

export function notFound() {
  return mobileJson(
    { error: { code: "not_found", message: "Not found" } },
    { status: 404 },
  );
}

export { readJson };
