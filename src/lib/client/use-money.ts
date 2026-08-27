"use client";

import useSWR, { mutate as globalMutate } from "swr";
import useSWRInfinite, { unstable_serialize } from "swr/infinite";
import { useCallback, useMemo } from "react";
import { apiSend, fetcher } from "@/lib/client/fetcher";
import type {
  ExpenseDTO,
  ExpensePageDTO,
  MoneyOverviewDTO,
  PersonDTO,
  PersonGroupDTO,
  PersonLedgerDTO,
  SettlementDTO,
} from "@/lib/types";

/**
 * Any write can move a balance, so the whole money namespace is refreshed
 * together rather than each screen guessing what else it touched.
 */
const EXPENSE_PAGE_SIZE = 20;

function expensePageKey(_pageIndex: number, previousPage: ExpensePageDTO | null) {
  if (previousPage && previousPage.nextCursor === null) return null;

  const params = new URLSearchParams({ limit: String(EXPENSE_PAGE_SIZE) });
  if (previousPage?.nextCursor) params.set("cursor", previousPage.nextCursor);
  return `/api/money/expenses?${params.toString()}`;
}

const EXPENSE_LIST_KEY = unstable_serialize(expensePageKey);

async function revalidateMoney() {
  await Promise.all([
    globalMutate(
      (key) =>
        typeof key === "string" &&
        key.startsWith("/api/money") &&
        !key.startsWith("/api/money/expenses?"),
    ),
    // Filter mutations intentionally skip SWR's `$inf$` metadata entries.
    // Revalidate the paginated expense list through its serialized key too.
    globalMutate(EXPENSE_LIST_KEY),
  ]);
}

function revalidateMoneyInBackground() {
  void revalidateMoney().catch(() => {
    // The write already succeeded. SWR will surface refresh failures on the
    // affected view and retry on focus/reconnect.
  });
}

export function useMoneyOverview() {
  const { data, isLoading, error, mutate } = useSWR<{ overview: MoneyOverviewDTO }>(
    "/api/money",
    fetcher,
  );

  return { overview: data?.overview ?? null, isLoading, error, mutate };
}

export function useExpenses() {
  const { data, error, isLoading, isValidating, size, setSize, mutate } =
    useSWRInfinite<ExpensePageDTO>(
      expensePageKey,
      fetcher,
    );

  const expenses = useMemo(() => {
    const seen = new Set<string>();
    return (
      data?.flatMap((page) =>
        page.expenses.filter((expense) => {
          if (seen.has(expense.id)) return false;
          seen.add(expense.id);
          return true;
        }),
      ) ?? []
    );
  }, [data]);
  const hasMore = Boolean(data?.at(-1)?.nextCursor);
  const isLoadingMore =
    isLoading ||
    (size > 0 && data !== undefined && typeof data[size - 1] === "undefined");
  const loadMore = useCallback(() => setSize((current) => current + 1), [setSize]);

  return {
    expenses,
    error,
    isLoading,
    isLoadingMore,
    isValidating,
    hasMore,
    loadMore,
    mutate,
  };
}

export function usePersonLedger(personId: string | null) {
  const { data, isLoading, mutate } = useSWR<{ ledger: PersonLedgerDTO }>(
    personId ? `/api/money/people/${personId}/ledger` : null,
    fetcher,
  );

  return { ledger: data?.ledger ?? null, isLoading, mutate };
}

// --- people -----------------------------------------------------------------

export async function createPerson(input: {
  name: string;
  color?: string;
  emoji?: string | null;
  defaultPercent?: number | null;
}) {
  const { person } = await apiSend<{ person: PersonDTO }>(
    "/api/money/people",
    "POST",
    input,
  );
  await revalidateMoney();
  return person;
}

export async function updatePerson(
  id: string,
  patch: Partial<Omit<PersonDTO, "id">>,
) {
  const { person } = await apiSend<{ person: PersonDTO }>(
    `/api/money/people/${id}`,
    "PATCH",
    patch,
  );
  await revalidateMoney();
  return person;
}

/** Archives anyone with history; removes anyone without it. */
export async function removePerson(id: string) {
  const res = await apiSend<{ deleted: boolean }>(
    `/api/money/people/${id}`,
    "DELETE",
  );
  await revalidateMoney();
  return res.deleted;
}

// --- groups -----------------------------------------------------------------

export async function createGroup(input: {
  name: string;
  color?: string;
  emoji?: string | null;
  memberIds: string[];
}) {
  const { group } = await apiSend<{ group: PersonGroupDTO }>(
    "/api/money/groups",
    "POST",
    input,
  );
  await revalidateMoney();
  return group;
}

export async function updateGroup(
  id: string,
  patch: Partial<Omit<PersonGroupDTO, "id">>,
) {
  const { group } = await apiSend<{ group: PersonGroupDTO }>(
    `/api/money/groups/${id}`,
    "PATCH",
    patch,
  );
  await revalidateMoney();
  return group;
}

export async function deleteGroup(id: string) {
  await apiSend(`/api/money/groups/${id}`, "DELETE");
  await revalidateMoney();
}

// --- expenses ---------------------------------------------------------------

export interface ExpenseInput {
  description?: string;
  amountCents: number;
  date?: string;
  paidByPersonId?: string | null;
  groupId?: string | null;
  splitMode?: "EQUAL" | "PERCENT" | "AMOUNT";
  includeMe?: boolean;
  participants?: {
    personId: string;
    percentBp?: number | null;
    amountCents?: number | null;
    gifted?: boolean;
  }[];
  notes?: string;
}

export async function createExpense(input: ExpenseInput) {
  const { expense } = await apiSend<{ expense: ExpenseDTO }>(
    "/api/money/expenses",
    "POST",
    input,
  );
  revalidateMoneyInBackground();
  return expense;
}

export async function updateExpense(id: string, patch: Partial<ExpenseInput>) {
  const { expense } = await apiSend<{ expense: ExpenseDTO }>(
    `/api/money/expenses/${id}`,
    "PATCH",
    patch,
  );
  revalidateMoneyInBackground();
  return expense;
}

export async function deleteExpense(id: string) {
  await apiSend(`/api/money/expenses/${id}`, "DELETE");
  revalidateMoneyInBackground();
}

// --- settlements ------------------------------------------------------------

export async function createSettlement(input: {
  personId: string;
  amountCents: number;
  direction?: "TO_ME" | "FROM_ME";
  date?: string;
  notes?: string;
}) {
  const { settlement } = await apiSend<{ settlement: SettlementDTO }>(
    "/api/money/settlements",
    "POST",
    input,
  );
  await revalidateMoney();
  return settlement;
}

export async function deleteSettlement(id: string) {
  await apiSend(`/api/money/settlements/${id}`, "DELETE");
  await revalidateMoney();
}
