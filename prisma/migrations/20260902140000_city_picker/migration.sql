-- Cities become something you pick, not something you type.
--
-- A place used to be a bare city name that a batch job later handed to a
-- geocoder, keeping whatever came back first. Nobody could say which
-- Springfield they meant, and two people in two different Cambridges shared
-- one pin. A place can now carry the id of a chosen city instead.

-- Every settlement the geocoder has told us about, cached for everybody.
-- Nothing personal is in here: a city name, a centroid, and the fields that
-- tell two same-named cities apart. Filled in as a side effect of answering a
-- search, which is what lets adding a place resolve its city from the database
-- rather than from the network.
CREATE TABLE "geo_cities" (
    -- GeoNames' id, not one of ours: stable, and shared by every place in the
    -- same city without comparing strings.
    "geonameId" INTEGER NOT NULL,
    "name" TEXT NOT NULL,
    "admin1" TEXT,
    "country" TEXT,
    "countryCode" TEXT,
    "latitude" DOUBLE PRECISION NOT NULL,
    "longitude" DOUBLE PRECISION NOT NULL,
    "timezone" TEXT,
    "population" INTEGER,
    "featureCode" TEXT,
    "fetchedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "geo_cities_pkey" PRIMARY KEY ("geonameId")
);

-- What a search answered with, so the second person to type "cam" is answered
-- from here. The order is the geocoder's ranking, which is better than ours.
CREATE TABLE "geo_searches" (
    "query" TEXT NOT NULL,
    "geonameIds" INTEGER[],
    "searchedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "geo_searches_pkey" PRIMARY KEY ("query")
);

-- Both nullable, and no foreign key to "geo_cities": that table is a cache,
-- and a place must not stop existing because a cache row was pruned. A place
-- with a null "cityId" is exactly what every place is today — a typed name
-- waiting for the batch.
ALTER TABLE "person_places" ADD COLUMN "cityId" INTEGER;
ALTER TABLE "person_places" ADD COLUMN "timezone" TEXT;
