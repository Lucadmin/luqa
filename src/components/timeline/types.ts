// Editor draft, in minutes since midnight of `day`. `endMin` may run past
// 1440 for an entry that crosses midnight.
export interface EntryDraft {
  id?: string; // present when editing an existing entry
  /** Calendar day the minutes below are relative to. */
  day: Date;
  description: string;
  categoryId: string | null;
  startMin: number;
  endMin: number;
  /** When filling a gap, the ceiling of the gap being chipped away. */
  gapEndMin?: number;
}

// Lightweight draft rendered directly on the timeline (drag-to-create).
export interface InlineDraft {
  /** Calendar day the minutes below are relative to. */
  day: Date;
  description: string;
  categoryId: string | null;
  startMin: number;
  endMin: number;
  /** Focus the inline title field on mount (mouse/desktop only). */
  autoFocus: boolean;
}
