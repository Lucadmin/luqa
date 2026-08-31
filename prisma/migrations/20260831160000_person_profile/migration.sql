-- Promote `people` from a money row to the person the whole app knows about.
--
-- Everything added here is nullable or defaulted: an existing person who has
-- only ever appeared on a bill stays valid, and no backfill is required.

CREATE TYPE "PlaceSource" AS ENUM ('GOOGLE', 'MANUAL');
CREATE TYPE "ChannelKind" AS ENUM ('PHONE', 'EMAIL', 'HANDLE');

ALTER TABLE "people" ADD COLUMN "nickname" TEXT;
ALTER TABLE "people" ADD COLUMN "photoUrl" TEXT;

-- Birthday as parts, not a date: most contacts carry a day and a month and no
-- year, and inventing a year produces a confidently wrong age.
ALTER TABLE "people" ADD COLUMN "birthdayYear" INTEGER;
ALTER TABLE "people" ADD COLUMN "birthdayMonth" INTEGER;
ALTER TABLE "people" ADD COLUMN "birthdayDay" INTEGER;

ALTER TABLE "people" ADD COLUMN "cadenceDays" INTEGER;
ALTER TABLE "people" ADD COLUMN "lastSeenAt" TIMESTAMP(3);

ALTER TABLE "people" ADD COLUMN "googleResourceName" TEXT;
ALTER TABLE "people" ADD COLUMN "googleEtag" TEXT;
ALTER TABLE "people" ADD COLUMN "googleSyncedAt" TIMESTAMP(3);

-- One Luqa person per Google contact. Scoped to the user so two accounts on
-- one deployment can each link the same contact.
CREATE UNIQUE INDEX "people_userId_googleResourceName_key"
  ON "people"("userId", "googleResourceName");

CREATE TABLE "person_places" (
    "id" TEXT NOT NULL,
    "personId" TEXT NOT NULL,
    "label" TEXT NOT NULL,
    "city" TEXT NOT NULL,
    "region" TEXT,
    "country" TEXT,
    "address" TEXT,
    "latitude" DOUBLE PRECISION,
    "longitude" DOUBLE PRECISION,
    "isPrimary" BOOLEAN NOT NULL DEFAULT false,
    "source" "PlaceSource" NOT NULL DEFAULT 'MANUAL',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "person_places_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "person_channels" (
    "id" TEXT NOT NULL,
    "personId" TEXT NOT NULL,
    "kind" "ChannelKind" NOT NULL,
    "label" TEXT,
    "value" TEXT NOT NULL,
    "source" "PlaceSource" NOT NULL DEFAULT 'MANUAL',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "person_channels_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "person_notes" (
    "id" TEXT NOT NULL,
    "personId" TEXT NOT NULL,
    "body" TEXT NOT NULL,
    "pinned" BOOLEAN NOT NULL DEFAULT false,
    "happenedOn" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "person_notes_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "person_gift_ideas" (
    "id" TEXT NOT NULL,
    "personId" TEXT NOT NULL,
    "idea" TEXT NOT NULL,
    "url" TEXT,
    "givenAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "person_gift_ideas_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "person_places_personId_idx" ON "person_places"("personId");
CREATE INDEX "person_channels_personId_idx" ON "person_channels"("personId");
CREATE INDEX "person_notes_personId_idx" ON "person_notes"("personId");
CREATE INDEX "person_gift_ideas_personId_idx" ON "person_gift_ideas"("personId");

-- Cascade rather than a tombstone of their own: these rows are only ever read
-- through their person, so when the person is gone there is nothing left that
-- could ask for them.
ALTER TABLE "person_places" ADD CONSTRAINT "person_places_personId_fkey"
  FOREIGN KEY ("personId") REFERENCES "people"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "person_channels" ADD CONSTRAINT "person_channels_personId_fkey"
  FOREIGN KEY ("personId") REFERENCES "people"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "person_notes" ADD CONSTRAINT "person_notes_personId_fkey"
  FOREIGN KEY ("personId") REFERENCES "people"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "person_gift_ideas" ADD CONSTRAINT "person_gift_ideas_personId_fkey"
  FOREIGN KEY ("personId") REFERENCES "people"("id") ON DELETE CASCADE ON UPDATE CASCADE;
