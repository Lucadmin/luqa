import "dotenv/config";
import { neon } from "@neondatabase/serverless";
const sql = neon(process.env.DATABASE_URL);

console.log(
  "newest 35 sessions by date:",
  await sql`
  SELECT s.date::date AS date, s."updatedAt",
         (SELECT count(*) FROM session_exercises e WHERE e."sessionId" = s.id) AS n
  FROM gym_sessions s WHERE s."deletedAt" IS NULL
  ORDER BY s.date DESC, s."createdAt" DESC LIMIT 35`,
);

console.log(
  "date range of empty vs filled:",
  await sql`
  SELECT (SELECT count(*) FROM session_exercises e WHERE e."sessionId" = s.id) = 0 AS empty,
         min(s.date)::date AS first, max(s.date)::date AS last, count(*)
  FROM gym_sessions s WHERE s."deletedAt" IS NULL GROUP BY 1`,
);
