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

export interface SettingsDTO {
  name: string | null;
  email: string;
  /** Hour (0–23) at which the logical day flips for stats. */
  dayStartHour: number;
  /** Tracked-time goal per day in minutes (reports goal line). */
  dailyGoalMinutes: number;
  /** 0 = Sunday, 1 = Monday. */
  weekStartsOn: number;
}

// --- Habits ---

export type HabitGoalType = "TASK" | "COUNT" | "TIME";
export type HabitGoalPeriod = "DAY" | "WEEK" | "MONTH";

export type HabitScheduleType =
  | "DAILY"
  | "WEEKDAYS"
  | "INTERVAL"
  | "TIMES_PER_WEEK"
  | "TIMES_PER_MONTH"
  | "TIMES_PER_YEAR"
  | "DATES";

/** Full habit configuration. */
export interface HabitDTO {
  id: string;
  name: string;
  icon: string | null;
  color: string;
  order: number;

  goalType: HabitGoalType;
  goalPeriod: HabitGoalPeriod;
  targetCount: number;
  targetSeconds: number;
  categoryId: string | null;

  scheduleType: HabitScheduleType;
  weekdays: number[];
  weekInterval: number;
  intervalDays: number;
  timesPerPeriod: number;
  anchorDate: string | null;
  dates: string[];
  excludedDates: string[];

  createdAt: string;
}

/** A habit plus its resolved progress for one specific day. */
export interface HabitDayDTO extends HabitDTO {
  /** Reps done (COUNT) or 0/1 (TASK). */
  count: number;
  /** Seconds tracked toward a TIME goal (derived for linked habits). */
  seconds: number;
  /** ISO instant a timer is running since, or null. */
  runningSince: string | null;
  /** Whether the day's goal is met. */
  done: boolean;
  /** For TIMES_PER_* schedules: days completed in the current period. */
  periodDone: number | null;
  /** For TIMES_PER_* schedules: the period quota. */
  periodTarget: number | null;
}

/** Per-habit analytics over a date range (for the stats view). */
export interface HabitStatDTO {
  habitId: string;
  /** date-key → goal fraction (0..1) for scheduled days with any progress. */
  fractions: Record<string, number>;
  /** Current consecutive-completion streak counting back from today. */
  streak: number;
  /** Best historical streak in the range. */
  bestStreak: number;
  /** Scheduled days in range that are complete. */
  completed: number;
  /** Scheduled days in range up to today. */
  scheduled: number;
}
