"use client";

import useSWR from "swr";
import { apiSend, fetcher } from "@/lib/client/fetcher";
import type { CategoryDTO } from "@/lib/types";

export function useCategories() {
  const { data, error, isLoading, mutate } = useSWR<{
    categories: CategoryDTO[];
  }>("/api/categories", fetcher);

  return {
    categories: data?.categories ?? [],
    isLoading,
    error,
    mutate,
  };
}

/** Find-or-create a category by name; returns the resolved category. */
export async function createCategory(
  name: string,
  color?: string,
): Promise<CategoryDTO> {
  const { category } = await apiSend<{ category: CategoryDTO }>(
    "/api/categories",
    "POST",
    { name, color },
  );
  return category;
}

export async function updateCategory(
  id: string,
  patch: Partial<Pick<CategoryDTO, "name" | "color" | "archived">>,
): Promise<CategoryDTO> {
  const { category } = await apiSend<{ category: CategoryDTO }>(
    `/api/categories/${id}`,
    "PATCH",
    patch,
  );
  return category;
}

export async function deleteCategory(id: string): Promise<void> {
  await apiSend(`/api/categories/${id}`, "DELETE");
}
