// Wire types shared between the API routes and the client.

export type EntrySource = "APP" | "GOOGLE";
export type SleepSource = "HEALTH_CONNECT" | "GOOGLE_HEALTH" | "MANUAL";

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

export interface SleepStageDTO {
  stage: string;
  /** ISO UTC. */
  startTime: string;
  /** ISO UTC. */
  endTime: string;
}

export interface SleepEntryDTO {
  id: string;
  source: SleepSource;
  externalId: string;
  title: string | null;
  sourceApp: string | null;
  /** ISO UTC. */
  startTime: string;
  /** ISO UTC. */
  endTime: string;
  sleepMinutes: number | null;
  awakeMinutes: number | null;
  lightMinutes: number | null;
  deepMinutes: number | null;
  remMinutes: number | null;
  stages: SleepStageDTO[];
  manualOverrideAt: string | null;
}

export interface SleepDayStatsDTO {
  totalMinutes: number;
  asleepMinutes: number;
  awakeMinutes: number;
  lightMinutes: number;
  deepMinutes: number;
  remMinutes: number;
  sessionCount: number;
  startTime: string | null;
  endTime: string | null;
}

export interface SleepReportDTO {
  dailySleep: Record<string, SleepDayStatsDTO>;
  totalMinutes: number;
  averageMinutes: number;
  daysWithSleep: number;
  bestDay: { dayKey: string; minutes: number } | null;
}

export interface GoogleHealthStatusDTO {
  connected: boolean;
  googleEmail: string | null;
  healthUserId: string | null;
  lastSynced: string | null;
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
  /** "YYYY-MM-DD" date of birth, or null until set. Anchors the life grid. */
  birthDate: string | null;
  /** Number of year-rows the life grid shows. */
  lifeExpectancyYears: number;
}

// --- Life overview ("life in weeks") ---

export interface LifePeriodDTO {
  id: string;
  name: string;
  color: string;
  /** "YYYY-MM-DD". */
  startDate: string;
  /** "YYYY-MM-DD", or null while ongoing. */
  endDate: string | null;
}

export interface WeekNoteDTO {
  /** 0-based age-week index since birth. */
  weekIndex: number;
  highlights: string;
  lessons: string;
  rating: number | null;
  milestone: string | null;
}

/** Everything the life screen needs in one payload. */
export interface LifeOverviewDTO {
  birthDate: string | null;
  lifeExpectancyYears: number;
  periods: LifePeriodDTO[];
  notes: WeekNoteDTO[];
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
