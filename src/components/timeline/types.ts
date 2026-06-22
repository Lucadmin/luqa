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
