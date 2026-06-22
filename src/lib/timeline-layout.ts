import { MINUTES_PER_DAY, SNAP_MINUTES } from "@/lib/time";
import type { TimeEntryDTO } from "@/lib/types";

export interface LaidOutEntry {
  entry: TimeEntryDTO;
  startMin: number;
  endMin: number;
  running: boolean;
  lane: number; // column index within its overlap cluster
  lanes: number; // total columns in that cluster
}

export interface Gap {
  startMin: number;
  endMin: number;
}

const clamp = (n: number) => Math.max(0, Math.min(MINUTES_PER_DAY, n));

interface Raw {
  entry: TimeEntryDTO;
  startMin: number;
  endMin: number;
  running: boolean;
}

function toRaw(
  entries: TimeEntryDTO[],
  dayStartMs: number,
  nowMin: number | null,
): Raw[] {
  return entries
    .map((entry) => {
      const startMin = clamp((Date.parse(entry.startTime) - dayStartMs) / 60000);
      const running = entry.endTime === null;
      const rawEnd = running
        ? (nowMin ?? MINUTES_PER_DAY)
        : (Date.parse(entry.endTime as string) - dayStartMs) / 60000;
      const endMin = Math.max(startMin + 1, clamp(rawEnd));
      return { entry, startMin, endMin, running };
    })
    .sort((a, b) => a.startMin - b.startMin || a.endMin - b.endMin);
}

/** Position entries, splitting overlapping ones into side-by-side lanes. */
export function computeLayout(
  entries: TimeEntryDTO[],
  dayStartMs: number,
  nowMin: number | null,
): LaidOutEntry[] {
  const raw = toRaw(entries, dayStartMs, nowMin);
  const result: LaidOutEntry[] = [];

  let i = 0;
  while (i < raw.length) {
    // Grow a cluster of transitively-overlapping entries.
    let clusterEnd = raw[i].endMin;
    let j = i + 1;
    while (j < raw.length && raw[j].startMin < clusterEnd) {
      clusterEnd = Math.max(clusterEnd, raw[j].endMin);
      j++;
    }
    const cluster = raw.slice(i, j);

    // Greedy lane assignment within the cluster.
    const laneEnds: number[] = [];
    const lanes: number[] = cluster.map((item) => {
      let lane = laneEnds.findIndex((end) => end <= item.startMin);
      if (lane === -1) {
        lane = laneEnds.length;
        laneEnds.push(item.endMin);
      } else {
        laneEnds[lane] = item.endMin;
      }
      return lane;
    });
    const laneCount = laneEnds.length;

    cluster.forEach((item, k) => {
      result.push({ ...item, lane: lanes[k], lanes: laneCount });
    });

    i = j;
  }

  return result;
}

/**
 * Interior gaps between activity, plus the trailing gap up to `nowMin` on
 * today. Slivers shorter than one snap step are ignored.
 */
export function computeGaps(
  entries: TimeEntryDTO[],
  dayStartMs: number,
  nowMin: number | null,
): Gap[] {
  const raw = toRaw(entries, dayStartMs, nowMin);
  if (raw.length === 0) return [];

  // Merge covered intervals.
  const merged: Gap[] = [];
  for (const r of raw) {
    const last = merged[merged.length - 1];
    if (last && r.startMin <= last.endMin) {
      last.endMin = Math.max(last.endMin, r.endMin);
    } else {
      merged.push({ startMin: r.startMin, endMin: r.endMin });
    }
  }

  const gaps: Gap[] = [];
  for (let k = 0; k < merged.length - 1; k++) {
    const gap = { startMin: merged[k].endMin, endMin: merged[k + 1].startMin };
    if (gap.endMin - gap.startMin >= SNAP_MINUTES) gaps.push(gap);
  }

  // Trailing gap up to "now" (today only).
  const lastEnd = merged[merged.length - 1].endMin;
  if (nowMin !== null && nowMin - lastEnd >= SNAP_MINUTES) {
    gaps.push({ startMin: lastEnd, endMin: nowMin });
  }

  return gaps;
}
