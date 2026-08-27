-- CreateTable
CREATE TABLE "mobile_sessions" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "deviceId" TEXT NOT NULL,
    "deviceName" TEXT,
    "accessTokenHash" TEXT NOT NULL,
    "accessExpiresAt" TIMESTAMP(3) NOT NULL,
    "refreshTokenHash" TEXT NOT NULL,
    "refreshExpiresAt" TIMESTAMP(3) NOT NULL,
    "lastUsedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "revokedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "mobile_sessions_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "mobile_sessions_accessTokenHash_key" ON "mobile_sessions"("accessTokenHash");

-- CreateIndex
CREATE UNIQUE INDEX "mobile_sessions_refreshTokenHash_key" ON "mobile_sessions"("refreshTokenHash");

-- CreateIndex
CREATE UNIQUE INDEX "mobile_sessions_userId_deviceId_key" ON "mobile_sessions"("userId", "deviceId");

-- CreateIndex
CREATE INDEX "mobile_sessions_userId_idx" ON "mobile_sessions"("userId");

-- CreateIndex
CREATE INDEX "mobile_sessions_refreshExpiresAt_idx" ON "mobile_sessions"("refreshExpiresAt");

-- AddForeignKey
ALTER TABLE "mobile_sessions" ADD CONSTRAINT "mobile_sessions_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
