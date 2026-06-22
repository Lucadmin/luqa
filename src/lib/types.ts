// Wire types shared between the API routes and the client.

export type EntrySource = "APP" | "GOOGLE";

export interface CategoryDTO {
  id: string;
  name: string;
  color: string;
  archived: boolean;
}

export interface TimeEntryDTO {
  id: string;
  description: string;
  categoryId: string | null;
  /** ISO UTC. */
  startTime: string;
  /** ISO UTC, or null while running. */
  endTime: string | null;
  source: EntrySource;
}

export interface SuggestionDTO {
  description: string;
  categoryId: string | null;
}
