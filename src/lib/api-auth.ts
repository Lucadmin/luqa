import { auth } from "@/auth";

/**
 * Returns the authenticated user's id, or null. Route handlers should
 * respond 401 when this is null.
 */
export async function getUserId(): Promise<string | null> {
  const session = await auth();
  return session?.user?.id ?? null;
}
