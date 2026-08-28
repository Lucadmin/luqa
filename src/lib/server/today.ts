import { db } from "@/lib/db";
import {
  pushEntryCreate,
  pushEntryDelete,
  pushEntryUpdate,
} from "@/lib/google/push-sync";
import { toCategoryDTO, toEntryDTO, toSleepDTO } from "@/lib/serializers";
import type {
  CreateCategoryInput,
  CreateEntryInput,
  UpdateEntryInput,
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

export class EntryRangeError extends Error {
  constructor() {
    super("End must be after start");
    this.name = "EntryRangeError";
  }
}

/**
 * Apply a partial edit. Returns null when the entry does not exist or belongs
 * to someone else, so callers can answer 404 without a second lookup.
 */
export async function updateTimeEntry(
  userId: string,
  id: string,
  input: UpdateEntryInput,
) {
  const existing = await db.timeEntry.findFirst({
    where: { id, userId, deletedAt: null },
  });
  if (!existing) return null;

  const { description, categoryId, startTime, endTime } = input;

  if (categoryId) {
    const owns = await db.category.findFirst({
      where: { id: categoryId, userId },
      select: { id: true },
    });
    if (!owns) throw new InvalidCategoryError();
  }

  // One side of the range may be unchanged, so validate the resulting pair
  // rather than the payload alone.
  const nextStart = startTime ? new Date(startTime) : existing.startTime;
  const nextEnd =
    endTime === undefined
      ? existing.endTime
      : endTime === null
        ? null
        : new Date(endTime);
  if (nextEnd && nextEnd <= nextStart) throw new EntryRangeError();

  const updated = await db.timeEntry.update({
    where: { id },
    data: {
      ...(description !== undefined ? { description } : {}),
      ...(categoryId !== undefined ? { categoryId } : {}),
      ...(startTime !== undefined ? { startTime: nextStart } : {}),
      ...(endTime !== undefined ? { endTime: nextEnd } : {}),
    },
  });

  // Push to Google Calendar (swallows its own errors).
  if (updated.endTime) {
    await pushEntryUpdate(
      userId,
      updated.id,
      updated.description,
      updated.categoryId,
      updated.startTime.toISOString(),
      updated.endTime.toISOString(),
    );
  }

  return toEntryDTO(updated);
}

/** Soft-delete an entry. False when it does not exist or is not this user's. */
export async function deleteTimeEntry(userId: string, id: string) {
  const existing = await db.timeEntry.findFirst({
    where: { id, userId, deletedAt: null },
    select: { id: true, googleEventId: true },
  });
  if (!existing) return false;

  await db.timeEntry.update({
    where: { id },
    data: { deletedAt: new Date() },
  });

  // Remove from Google Calendar (swallows its own errors).
  if (existing.googleEventId) {
    await pushEntryDelete(userId, existing.googleEventId);
  }
  return true;
}

/**
 * Sleep sessions that *woke up* inside the window — sleep is attributed to the
 * day it ends in, which is the day the timeline shows it under.
 */
export async function listSleepEntries(userId: string, window: EntryWindow) {
  const entries = await db.sleepEntry.findMany({
    where: {
      userId,
      deletedAt: null,
      endTime: { gte: window.from, lt: window.to },
    },
    orderBy: { endTime: "asc" },
  });
  return entries.map(toSleepDTO);
}
