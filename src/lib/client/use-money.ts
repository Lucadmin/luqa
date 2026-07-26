"use client";

import useSWR, { mutate as globalMutate } from "swr";
import useSWRInfinite from "swr/infinite";
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
function revalidateMoney() {
  return globalMutate(
    (key) => typeof key === "string" && key.startsWith("/api/money"),
  );
}

export function useMoneyOverview() {
  const { data, isLoading, error, mutate } = useSWR<{ overview: MoneyOverviewDTO }>(
    "/api/money",
    fetcher,
  );

  return { overview: data?.overview ?? null, isLoading, error, mutate };
}

const EXPENSE_PAGE_SIZE = 20;

export function useExpenses() {
  const { data, error, isLoading, isValidating, size, setSize, mutate } =
    useSWRInfinite<ExpensePageDTO>(
      (_pageIndex, previousPage) => {
        if (previousPage && previousPage.nextCursor === null) return null;

        const params = new URLSearchParams({
          limit: String(EXPENSE_PAGE_SIZE),
        });
        if (previousPage?.nextCursor) {
          params.set("cursor", previousPage.nextCursor);
        }
        return `/api/money/expenses?${params.toString()}`;
      },
      fetcher,
    );

  const seen = new Set<string>();
  const expenses =
    data?.flatMap((page) =>
      page.expenses.filter((expense) => {
        if (seen.has(expense.id)) return false;
        seen.add(expense.id);
        return true;
      }),
    ) ?? [];
  const hasMore = Boolean(data?.at(-1)?.nextCursor);
  const isLoadingMore =
    isLoading ||
    (size > 0 && data !== undefined && typeof data[size - 1] === "undefined");

  return {
    expenses,
    error,
    isLoading,
    isLoadingMore,
    isValidating,
    hasMore,
    loadMore: () => setSize(size + 1),
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
  await revalidateMoney();
  return expense;
}

export async function updateExpense(id: string, patch: Partial<ExpenseInput>) {
  const { expense } = await apiSend<{ expense: ExpenseDTO }>(
    `/api/money/expenses/${id}`,
    "PATCH",
    patch,
  );
  await revalidateMoney();
  return expense;
}

export async function deleteExpense(id: string) {
  await apiSend(`/api/money/expenses/${id}`, "DELETE");
  await revalidateMoney();
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
