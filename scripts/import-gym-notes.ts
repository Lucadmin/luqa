// One-off: load the hand-kept gym-notes.md into the database for a specific
// user. Not part of the app — run once with `npx tsx scripts/import-gym-notes.ts`.
//
// Reuses the same parser and exercise-resolution logic the app itself uses
// (src/lib/gym.ts, src/lib/server/gym.ts), so what lands in the database reads
// exactly the way the gym screen would have written it.
import "dotenv/config";
import { randomUUID } from "node:crypto";
import { readFileSync } from "node:fs";
import path from "node:path";
import { db } from "@/lib/db";
import { exerciseKey, parseGymMarkdown, parseSetLine } from "@/lib/gym";
import { resolveExerciseIds } from "@/lib/server/gym";

const OWNER_EMAIL = process.env.APP_OWNER_EMAIL?.trim() || "luca.ilchen@gmail.com";
const NOTES_PATH = path.join(process.cwd(), "gym-notes.md");

function dateFromKey(key: string): Date {
  return new Date(`${key}T00:00:00.000Z`);
}

async function main() {
  const user = await db.user.findUnique({ where: { email: OWNER_EMAIL } });
  if (!user) {
    throw new Error(
      `No user with email ${OWNER_EMAIL} — sign up first, then re-run this.`,
    );
  }

  const markdown = readFileSync(NOTES_PATH, "utf8");
  const imported = parseGymMarkdown(markdown);
  console.log(`Parsed ${imported.length} sessions from ${NOTES_PATH}`);

  const already = await db.gymSession.findMany({
    where: { userId: user.id },
    select: { date: true },
  });
  const existingDates = new Set(already.map((s) => s.date.toISOString().slice(0, 10)));

  const sessions = imported.filter((s) => !existingDates.has(s.date));
  const skipped = imported.length - sessions.length;
  if (skipped > 0) {
    console.log(`Skipping ${skipped} session(s) already logged for this user.`);
  }
  if (sessions.length === 0) {
    console.log("Nothing new to import.");
    return;
  }

  // --- gyms -------------------------------------------------------------

  const existingLocations = await db.gymLocation.findMany({
    where: { userId: user.id },
    select: { id: true, code: true },
  });
  const locationByCode = new Map(
    existingLocations.map((l) => [l.code.toLowerCase(), l.id]),
  );

  const codes = [
    ...new Set(sessions.map((s) => s.locationCode).filter((c) => c.length > 0)),
  ];
  const newCodes = codes.filter((c) => !locationByCode.has(c.toLowerCase()));

  if (newCodes.length > 0) {
    const base = existingLocations.length;
    await db.gymLocation.createMany({
      data: newCodes.map((code, i) => ({
        userId: user.id,
        code,
        // Name = code for now; rename in the Gyms sheet once they're in.
        name: code,
        order: base + i,
      })),
      skipDuplicates: true,
    });
    const refreshed = await db.gymLocation.findMany({
      where: { userId: user.id },
      select: { id: true, code: true },
    });
    locationByCode.clear();
    for (const l of refreshed) locationByCode.set(l.code.toLowerCase(), l.id);
    console.log(`Created gyms: ${newCodes.join(", ")}`);
  }

  // --- exercises ----------------------------------------------------------

  const names = sessions.flatMap((s) => s.exercises.map((e) => e.name));
  const existingExerciseNames = new Set(
    (await db.exercise.findMany({ where: { userId: user.id }, select: { name: true } })).map(
      (e) => exerciseKey(e.name),
    ),
  );
  const newExerciseCount = new Set(
    names.map(exerciseKey).filter((k) => k && !existingExerciseNames.has(k)),
  ).size;

  const idByKey = await resolveExerciseIds(user.id, names);
  console.log(`Exercises: ${newExerciseCount} new, ${idByKey.size} total in use.`);

  // --- build rows -----------------------------------------------------------

  const sessionRows: {
    id: string;
    userId: string;
    date: Date;
    locationId: string | null;
    notes: string;
  }[] = [];
  const exerciseRows: {
    id: string;
    sessionId: string;
    exerciseId: string;
    order: number;
    raw: string;
    notes: string;
  }[] = [];
  const setRows: {
    sessionExerciseId: string;
    order: number;
    weight: number | null;
    reps: number | null;
    note: string | null;
  }[] = [];

  let setCount = 0;

  for (const session of sessions) {
    const sessionId = randomUUID();
    sessionRows.push({
      id: sessionId,
      userId: user.id,
      date: dateFromKey(session.date),
      locationId: session.locationCode
        ? (locationByCode.get(session.locationCode.toLowerCase()) ?? null)
        : null,
      notes: session.notes,
    });

    session.exercises.forEach((entry, order) => {
      const exerciseId = idByKey.get(exerciseKey(entry.name));
      if (!exerciseId) return;

      const rowId = randomUUID();
      exerciseRows.push({
        id: rowId,
        sessionId,
        exerciseId,
        order,
        raw: entry.raw,
        notes: "",
      });

      parseSetLine(entry.raw).sets.forEach((set, setOrder) => {
        setCount++;
        setRows.push({
          sessionExerciseId: rowId,
          order: setOrder,
          weight: set.weight,
          reps: set.reps,
          note: set.note,
        });
      });
    });
  }

  await db.$transaction(async (tx) => {
    await tx.gymSession.createMany({ data: sessionRows });
    await tx.sessionExercise.createMany({ data: exerciseRows });
    await tx.gymSet.createMany({ data: setRows });
  });

  console.log(
    `Imported ${sessionRows.length} sessions, ${exerciseRows.length} exercise entries, ${setCount} sets.`,
  );
}

main()
  .catch((err) => {
    console.error(err);
    process.exitCode = 1;
  })
  .finally(() => db.$disconnect());
