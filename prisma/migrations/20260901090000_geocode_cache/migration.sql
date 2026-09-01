-- Cities resolved to a point, once, for everybody.
--
-- Not scoped to a user: "Munich, DE" is the same place whoever asked, and the
-- cache is what makes a rate-limited public geocoder usable at all. A lookup
-- that found nothing is stored too, with null coordinates, so a misspelt city
-- is not retried on every sync for ever.
CREATE TABLE "geocode_cache" (
    "query" TEXT NOT NULL,
    "latitude" DOUBLE PRECISION,
    "longitude" DOUBLE PRECISION,
    "city" TEXT,
    "country" TEXT,
    "resolvedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "geocode_cache_pkey" PRIMARY KEY ("query")
);
