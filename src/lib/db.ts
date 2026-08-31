import { neonConfig } from "@neondatabase/serverless";
import { PrismaNeon } from "@prisma/adapter-neon";
import ws from "ws";
import { PrismaClient } from "@/generated/prisma/client";

// Neon's serverless driver needs a WebSocket constructor outside the browser.
if (typeof WebSocket === "undefined") {
  neonConfig.webSocketConstructor = ws;
}

const createPrismaClient = () => {
  const adapter = new PrismaNeon({
    connectionString: process.env.DATABASE_URL,
  });
  return new PrismaClient({ adapter });
};

// Reuse the client across hot reloads / serverless invocations.
const globalForPrisma = globalThis as unknown as {
  prisma: ReturnType<typeof createPrismaClient> | undefined;
};

const base = globalForPrisma.prisma ?? createPrismaClient();

if (process.env.NODE_ENV !== "production") {
  globalForPrisma.prisma = base;
}

/// The rows that carry a tombstone. Deleting one of these sets `deletedAt`
/// rather than removing it, so a phone that has been offline can still be told
/// the thing is gone.
const TOMBSTONED = new Set([
  "Person",
  "PersonGroup",
  "Expense",
  "Settlement",
  "Category",
  "GymLocation",
  "Exercise",
  "GymSession",
]);

type ReadArgs = { where?: Record<string, unknown> };

/// Narrows a read to the rows that still exist, for the models that can be
/// deleted without going away.
function alive<T>(
  model: string,
  args: ReadArgs,
  query: (args: ReadArgs) => T,
): T {
  if (!TOMBSTONED.has(model)) return query(args);
  return query({ ...args, where: { ...args.where, deletedAt: null } });
}

/// What every route and page reads through. Deleted rows do not exist here.
///
/// One extension rather than a `deletedAt: null` on 153 call sites: a filter
/// that has to be remembered is a filter that eventually is not, and the way
/// that fails is a bill the user deleted reappearing on their phone.
///
/// Reads only. A mutation that names a row by id has to be able to reach a
/// deleted one — restoring, and re-claiming an id a phone is replaying, both
/// depend on it.
///
/// The one thing this cannot reach is a nested `include`: Prisma forbids
/// mutating those, since it would change the result type. Relations of
/// tombstoned rows are therefore filtered explicitly at their call sites.
export const db = base.$extends({
  name: "hide-deleted",
  query: {
    $allModels: {
      findFirst: ({ model, args, query }) => alive(model, args, query),
      findFirstOrThrow: ({ model, args, query }) => alive(model, args, query),
      findMany: ({ model, args, query }) => alive(model, args, query),
      findUnique: ({ model, args, query }) => alive(model, args, query),
      findUniqueOrThrow: ({ model, args, query }) => alive(model, args, query),
      count: ({ model, args, query }) => alive(model, args, query),
      aggregate: ({ model, args, query }) => alive(model, args, query),
    },
  },
});

/// The same database with nothing hidden, for the sync endpoints alone.
///
/// A delta feed exists precisely to report deletions, so it is the one caller
/// that has to see them. Nothing else should import this.
export const dbWithDeleted = base;

/// The client handed to a `db.$transaction` callback.
///
/// Spelled out because extending the client changes this type, and helpers
/// that take a transaction have to name the extended one or they will not
/// accept it.
export type DbTransaction = Omit<
  typeof db,
  "$connect" | "$disconnect" | "$on" | "$transaction" | "$use" | "$extends"
>;
