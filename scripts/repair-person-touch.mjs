import "dotenv/config";
import { db } from "@/lib/db";
import { touchData } from "@/lib/person-profile";

/**
 * One-off repair for rows stranded by the no-op `touchPerson` (fixed 2026-09-01).
 *
 * Every place, note and gift written before the fix landed on the server
 * without its person's `updatedAt` moving, so the delta feed never carried it
 * and no device has seen it. Bumping the parent puts the row back in the feed.
 *
 * Only touches people whose children are genuinely newer than they are, and
 * only ever moves a timestamp — no content is written.
 */
const people = await db.person.findMany({
  select: {
    id: true,
    name: true,
    updatedAt: true,
    places: { select: { updatedAt: true } },
    notes: { select: { updatedAt: true } },
    gifts: { select: { updatedAt: true } },
    channels: { select: { updatedAt: true } },
  },
});

const stranded = people.filter((person) => {
  const children = [
    ...person.places,
    ...person.notes,
    ...person.gifts,
    ...person.channels,
  ];
  return children.some((child) => child.updatedAt > person.updatedAt);
});

const apply = process.argv.includes("--apply");
console.log(`${people.length} people, ${stranded.length} with stranded children`);
for (const person of stranded) {
  console.log(` - ${person.name}`);
}

if (!apply) {
  console.log("\ndry run — pass --apply to repair");
} else {
  for (const person of stranded) {
    await db.person.update({ where: { id: person.id }, data: touchData() });
  }
  console.log(`\ntouched ${stranded.length}`);
}
