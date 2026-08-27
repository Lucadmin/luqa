import { db } from "@/lib/db";
import { pushEntryCreate } from "@/lib/google/push-sync";
import { toCategoryDTO, toEntryDTO } from "@/lib/serializers";
import type {
  CreateCategoryInput,
  CreateEntryInput,
} from "@/lib/validations";

const CATEGORY_PALETTE = [
  "#6366f1",
  "#ec4899",
  "#f59e0b",
  "#10b981",
  "#3b82f6",
  "#8b5cf6",
  "#ef4444",
  "#14b8a6",
  "#f97316",
  "#06b6d4",
];

export class InvalidCategoryError extends Error {
  constructor() {
    super("Unknown category");
    this.name = "InvalidCategoryError";
  }
}

export interface EntryWindow {
  from: Date;
  to: Date;
}

export type EntryWindowResult =
  | ({ ok: true } & EntryWindow)
  | { ok: false; message: string };

export function parseEntryWindow(params: URLSearchParams): EntryWindowResult {
  const from = params.get("from");
  const to = params.get("to");
  if (!from || !to) {
    return { ok: false, message: "from and to are required" };
  }

  const fromDate = new Date(from);
  const toDate = new Date(to);
  if (
    Number.isNaN(fromDate.getTime()) ||
    Number.isNaN(toDate.getTime()) ||
    toDate <= fromDate
  ) {
    return { ok: false, message: "Invalid from/to window" };
  }
  return { ok: true, from: fromDate, to: toDate };
}

export async function listCategories(userId: string) {
  const categories = await db.category.findMany({
    where: { userId },
    orderBy: { name: "asc" },
  });
  return categories.map(toCategoryDTO);
}

export async function createCategory(
  userId: string,
  input: CreateCategoryInput,
) {
  const existing = await db.category.findFirst({
    where: {
      userId,
      name: { equals: input.name, mode: "insensitive" },
    },
  });
  if (existing) {
    return { category: toCategoryDTO(existing), created: false };
  }

  const count = await db.category.count({ where: { userId } });
  const category = await db.category.create({
    data: {
      userId,
      name: input.name,
      color: input.color ?? CATEGORY_PALETTE[count % CATEGORY_PALETTE.length],
    },
  });
  return { category: toCategoryDTO(category), created: true };
}

export async function listTimeEntries(userId: string, window: EntryWindow) {
  const entries = await db.timeEntry.findMany({
    where: {
      userId,
      deletedAt: null,
      startTime: { lt: window.to },
      OR: [{ endTime: null }, { endTime: { gt: window.from } }],
    },
    orderBy: { startTime: "asc" },
  });
  return entries.map(toEntryDTO);
}

export async function createTimeEntry(
  userId: string,
  input: CreateEntryInput,
) {
  if (input.categoryId) {
    const category = await db.category.findFirst({
      where: { id: input.categoryId, userId },
      select: { id: true },
    });
    if (!category) throw new InvalidCategoryError();
  }

  const start = new Date(input.startTime);
  const entry = await db.$transaction(async (tx) => {
    if (!input.endTime) {
      await tx.timeEntry.updateMany({
        where: { userId, endTime: null, deletedAt: null },
        data: { endTime: start },
      });
    }
    return tx.timeEntry.create({
      data: {
        userId,
        description: input.description ?? "",
        categoryId: input.categoryId ?? null,
        startTime: start,
        endTime: input.endTime ? new Date(input.endTime) : null,
        source: "APP",
      },
    });
  });

  if (entry.endTime) {
    await pushEntryCreate(
      userId,
      entry.id,
      entry.description,
      entry.categoryId,
      entry.startTime.toISOString(),
      entry.endTime.toISOString(),
    );
  }
  return toEntryDTO(entry);
}
