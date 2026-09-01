-- An INTERVAL habit can now count from the last time it was actually done,
-- rather than from a fixed anchor.
--
-- "Shave every second day" on a fixed grid keeps insisting on the original odd
-- days: miss Wednesday, do it Thursday, and Friday is still the day it wants.
-- Counting from the last completion shifts the whole cycle instead, which is
-- what someone means by "every second day".
--
-- Defaults to false, so every habit that already exists keeps the fixed grid it
-- was created with.

ALTER TABLE "habits"
  ADD COLUMN "intervalFromLastDone" BOOLEAN NOT NULL DEFAULT false;
