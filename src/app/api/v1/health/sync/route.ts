import {
  invalidInput,
  invalidJson,
  mobileAuthError,
  mobileJson,
  readJson,
} from "@/lib/mobile-api-response";
import { listHealthSyncStates } from "@/lib/health/samples";
import { authenticateMobileRequest } from "@/lib/server/mobile-auth";
import { applyHealthSync } from "@/lib/server/health-sync";
import { healthSyncSchema } from "@/lib/mobile-api-validation";

// GET /api/v1/health/sync
// What the server last accepted, per source and metric. The device uses this to
// decide between an incremental push and a full backfill after a reinstall.
export async function GET(request: Request) {
  let session;
  try {
    session = await authenticateMobileRequest(request);
  } catch (error) {
    const response = mobileAuthError(error);
    if (response) return response;
    throw error;
  }

  return mobileJson({ states: await listHealthSyncStates(session.userId) });
}

// POST /api/v1/health/sync
// Ingests one push from a device. Idempotent: replaying the same batch upserts
// onto the same rows by provider record id.
export async function POST(request: Request) {
  let session;
  try {
    session = await authenticateMobileRequest(request);
  } catch (error) {
    const response = mobileAuthError(error);
    if (response) return response;
    throw error;
  }

  let body: unknown;
  try {
    body = await readJson(request);
  } catch {
    return invalidJson();
  }
  const parsed = healthSyncSchema.safeParse(body);
  if (!parsed.success) return invalidInput(parsed.error.flatten());

  const result = await applyHealthSync(session.userId, parsed.data);
  return mobileJson(result);
}
