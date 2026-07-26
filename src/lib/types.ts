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
  /** ISO 4217 code every amount in the money screens is formatted with. */
  currency: string;
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

// --- Shared expenses ---
//
// Every amount is integer cents, and every balance is signed from the user's
// point of view: positive means "this person owes me".

export type SplitMode = "EQUAL" | "PERCENT" | "AMOUNT";
export type SettlementDirection = "TO_ME" | "FROM_ME";

export interface PersonDTO {
  id: string;
  name: string;
  color: string;
  emoji: string | null;
  /** Usual cut of a bill, in whole percent. Null = share equally. */
  defaultPercent: number | null;
  order: number;
  archived: boolean;
}

/** A person plus the numbers the overview shows next to their name. */
export interface PersonBalanceDTO extends PersonDTO {
  /** Positive = they owe you, negative = you owe them, 0 = settled up. */
  balanceCents: number;
  /** All-time total you covered for them as a treat. Never part of a balance. */
  coveredCents: number;
  /** "YYYY-MM-DD" of their most recent expense or settlement, or null. */
  lastActivity: string | null;
}

export interface PersonGroupDTO {
  id: string;
  name: string;
  color: string;
  emoji: string | null;
  order: number;
  archived: boolean;
  memberIds: string[];
}

export interface ExpenseShareDTO {
  personId: string;
  amountCents: number;
  /** Basis points of the bill, 10000 = 100%. */
  percentBp: number | null;
  /** You covered this slice as a treat — tracked, but not a debt. */
  gifted: boolean;
}

export interface ExpenseDTO {
  id: string;
  description: string;
  amountCents: number;
  /** "YYYY-MM-DD". */
  date: string;
  /** Who fronted the money. Null = you did. */
  paidByPersonId: string | null;
  groupId: string | null;
  splitMode: SplitMode;
  /** Your own slice of the bill. */
  myShareCents: number;
  notes: string;
  shares: ExpenseShareDTO[];
  createdAt: string;
}

/** One cursor-paginated page of expenses, newest first. */
export interface ExpensePageDTO {
  expenses: ExpenseDTO[];
  nextCursor: string | null;
}

export interface SettlementDTO {
  id: string;
  personId: string;
  amountCents: number;
  direction: SettlementDirection;
  /** "YYYY-MM-DD". */
  date: string;
  notes: string;
  createdAt: string;
}

/** Everything the money screen needs in one payload. */
export interface MoneyOverviewDTO {
  currency: string;
  people: PersonBalanceDTO[];
  groups: PersonGroupDTO[];
  /** Sum of the positive balances. */
  owedToYouCents: number;
  /** Sum of the negative balances, as a positive number. */
  youOweCents: number;
  /** owedToYou − youOwe. */
  netCents: number;
  /** All-time total covered as treats, across everyone. */
  coveredCents: number;
}

/** One row of a person's history. */
export interface LedgerItemDTO {
  kind: "expense" | "settlement";
  id: string;
  /** "YYYY-MM-DD". */
  date: string;
  title: string;
  /** Effect on the balance: positive raises what they owe you. Gifts are 0. */
  deltaCents: number;
  /** Their slice of the bill (expenses) or the amount moved (settlements). */
  shareCents: number;
  gifted: boolean;
  /** The whole bill, for context. Null on settlements. */
  amountCents: number | null;
  /** Null = you paid. */
  paidByPersonId: string | null;
  direction: SettlementDirection | null;
  /** Full editor state for expense rows. Null on settlements. */
  expense: ExpenseDTO | null;
  createdAt: string;
}

export interface PersonLedgerDTO {
  person: PersonDTO;
  currency: string;
  balanceCents: number;
  coveredCents: number;
  /** Covered so far in the current calendar year. */
  coveredThisYearCents: number;
  items: LedgerItemDTO[];
}

// --- Gym log ---

export interface GymLocationDTO {
  id: string;
  /** Short form typed while logging, e.g. "STR". */
  code: string;
  name: string;
  color: string;
  order: number;
  archived: boolean;
}

export interface GymSetDTO {
  weight: number | null;
  reps: number | null;
  note: string | null;
}

export interface SessionExerciseDTO {
  id: string;
  exerciseId: string;
  /** Resolved name, so a row never needs a second lookup to render. */
  name: string;
  order: number;
  /** The set line exactly as typed. */
  raw: string;
  notes: string;
  /** Read out of `raw` by the server — the client never sends these. */
  sets: GymSetDTO[];
}

export interface GymSessionDTO {
  id: string;
  /** "YYYY-MM-DD". */
  date: string;
  locationId: string | null;
  notes: string;
  exercises: SessionExerciseDTO[];
  createdAt: string;
}

export interface ExerciseDTO {
  id: string;
  name: string;
  notes: string;
  archived: boolean;
  /** How many sessions it appears in. */
  sessionCount: number;
  /** "YYYY-MM-DD" it was last done, or null. */
  lastPerformed: string | null;
  /** Gyms it has been done at — what makes the location filter worth showing. */
  locationIds: string[];
  /** The set line from the last time it was done, ready to be reused. */
  lastRaw: string | null;
  /** Which gym that last time was at. */
  lastLocationId: string | null;
}

/** Everything the gym screen needs in one payload. */
export interface GymOverviewDTO {
  locations: GymLocationDTO[];
  exercises: ExerciseDTO[];
  /** Newest first. */
  sessions: GymSessionDTO[];
  totalSessions: number;
}

/** One past performance of an exercise, for the history sheet and its graph. */
export interface ExercisePointDTO {
  sessionId: string;
  /** "YYYY-MM-DD". */
  date: string;
  locationId: string | null;
  raw: string;
  notes: string;
  sets: GymSetDTO[];
  topWeight: number | null;
  /** Epley estimate, so a heavy triple compares against a light twelve. */
  best1RM: number | null;
  totalReps: number;
  volume: number;
  /** Beat every e1RM before it. */
  isPr: boolean;
}

export interface ExerciseHistoryDTO {
  exercise: ExerciseDTO;
  /** Oldest first, so the graph reads left to right. */
  points: ExercisePointDTO[];
  /** Best e1RM within the current filter. */
  bestEver: number | null;
  /** Heaviest weight handled within the current filter. */
  heaviest: number | null;
}

/** What an import would do / did. */
export interface GymImportResultDTO {
  sessions: number;
  exercises: number;
  sets: number;
  newExercises: string[];
  newLocations: string[];
  /** Dates already in the log that the import skipped or replaced. */
  duplicateDates: string[];
}
