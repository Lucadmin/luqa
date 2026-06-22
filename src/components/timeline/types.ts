// Editor draft, in timeline-local minutes-since-midnight.
export interface EntryDraft {
  id?: string; // present when editing an existing entry
  description: string;
  categoryId: string | null;
  startMin: number;
  endMin: number;
  /** When filling a gap, the ceiling of the gap being chipped away. */
  gapEndMin?: number;
}

// Lightweight draft rendered directly on the timeline (drag-to-create).
export interface InlineDraft {
  description: string;
  categoryId: string | null;
  startMin: number;
  endMin: number;
  /** Focus the inline title field on mount (mouse/desktop only). */
  autoFocus: boolean;
}
