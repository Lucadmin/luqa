-- Who was there.
--
-- Tagging a block of time with people is what makes "last seen" a fact the app
-- already knows rather than one the user has to type. A join table rather than
-- an array so a person's shared history can be read from their side too.
CREATE TABLE "time_entry_people" (
    "timeEntryId" TEXT NOT NULL,
    "personId" TEXT NOT NULL,

    CONSTRAINT "time_entry_people_pkey" PRIMARY KEY ("timeEntryId","personId")
);

CREATE INDEX "time_entry_people_personId_idx" ON "time_entry_people"("personId");

ALTER TABLE "time_entry_people" ADD CONSTRAINT "time_entry_people_timeEntryId_fkey"
  FOREIGN KEY ("timeEntryId") REFERENCES "time_entries"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "time_entry_people" ADD CONSTRAINT "time_entry_people_personId_fkey"
  FOREIGN KEY ("personId") REFERENCES "people"("id") ON DELETE CASCADE ON UPDATE CASCADE;
