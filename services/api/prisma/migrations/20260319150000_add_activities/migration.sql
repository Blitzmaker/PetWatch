CREATE TABLE "Activity" (
  "id" TEXT NOT NULL,
  "name" TEXT NOT NULL,
  "kcalPerMinute" DOUBLE PRECISION NOT NULL,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL,

  CONSTRAINT "Activity_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "ActivityEntry" (
  "id" TEXT NOT NULL,
  "dogId" TEXT NOT NULL,
  "activityId" TEXT NOT NULL,
  "durationMinutes" INTEGER NOT NULL,
  "performedAt" TIMESTAMP(3) NOT NULL,
  "kcalPerMinuteSnapshot" DOUBLE PRECISION NOT NULL,
  "kcalMultiplier" DOUBLE PRECISION NOT NULL,
  "kcalBurned" DOUBLE PRECISION NOT NULL,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT "ActivityEntry_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "Activity_name_key" ON "Activity"("name");
CREATE INDEX "ActivityEntry_dogId_performedAt_idx" ON "ActivityEntry"("dogId", "performedAt");
CREATE INDEX "ActivityEntry_activityId_idx" ON "ActivityEntry"("activityId");

ALTER TABLE "ActivityEntry" ADD CONSTRAINT "ActivityEntry_dogId_fkey" FOREIGN KEY ("dogId") REFERENCES "Dog"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "ActivityEntry" ADD CONSTRAINT "ActivityEntry_activityId_fkey" FOREIGN KEY ("activityId") REFERENCES "Activity"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
