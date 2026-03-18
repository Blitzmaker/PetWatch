-- CreateEnum
CREATE TYPE "Sex" AS ENUM ('MALE', 'FEMALE', 'UNKNOWN');
CREATE TYPE "ActivityLevel" AS ENUM ('LOW', 'MEDIUM', 'HIGH');
CREATE TYPE "MealType" AS ENUM ('BREAKFAST', 'LUNCH', 'DINNER', 'SNACK');

CREATE TABLE "User" (
  "id" TEXT NOT NULL,
  "email" TEXT NOT NULL,
  "passwordHash" TEXT NOT NULL,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL,
  CONSTRAINT "User_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "RefreshToken" (
  "id" TEXT NOT NULL,
  "userId" TEXT NOT NULL,
  "tokenHash" TEXT NOT NULL,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "expiresAt" TIMESTAMP(3) NOT NULL,
  CONSTRAINT "RefreshToken_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "Dog" (
  "id" TEXT NOT NULL,
  "userId" TEXT NOT NULL,
  "name" TEXT NOT NULL,
  "birthdate" TIMESTAMP(3),
  "sex" "Sex" NOT NULL DEFAULT 'UNKNOWN',
  "targetWeightKg" DOUBLE PRECISION,
  "activityLevel" "ActivityLevel" NOT NULL DEFAULT 'MEDIUM',
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL,
  CONSTRAINT "Dog_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "WeightEntry" (
  "id" TEXT NOT NULL,
  "dogId" TEXT NOT NULL,
  "date" TIMESTAMP(3) NOT NULL,
  "weightKg" DOUBLE PRECISION NOT NULL,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "WeightEntry_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "Food" (
  "id" TEXT NOT NULL,
  "barcode" TEXT NOT NULL,
  "name" TEXT NOT NULL,
  "brand" TEXT,
  "kcalPer100g" INTEGER NOT NULL,
  "proteinPercent" DOUBLE PRECISION,
  "fatPercent" DOUBLE PRECISION,
  "crudeAshPercent" DOUBLE PRECISION,
  "crudeFiberPercent" DOUBLE PRECISION,
  "createdByUserId" TEXT,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL,
  CONSTRAINT "Food_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "Meal" (
  "id" TEXT NOT NULL,
  "dogId" TEXT NOT NULL,
  "eatenAt" TIMESTAMP(3) NOT NULL,
  "note" TEXT,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL,
  CONSTRAINT "Meal_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "MealEntry" (
  "id" TEXT NOT NULL,
  "mealId" TEXT NOT NULL,
  "foodId" TEXT NOT NULL,
  "grams" DOUBLE PRECISION NOT NULL,
  "mealType" "MealType" NOT NULL DEFAULT 'DINNER',
  CONSTRAINT "MealEntry_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "User_email_key" ON "User"("email");
CREATE UNIQUE INDEX "Food_barcode_key" ON "Food"("barcode");
CREATE INDEX "RefreshToken_userId_idx" ON "RefreshToken"("userId");
CREATE INDEX "Dog_userId_idx" ON "Dog"("userId");
CREATE INDEX "WeightEntry_dogId_date_idx" ON "WeightEntry"("dogId", "date");
CREATE INDEX "Meal_dogId_eatenAt_idx" ON "Meal"("dogId", "eatenAt");
CREATE INDEX "MealEntry_mealId_idx" ON "MealEntry"("mealId");
CREATE INDEX "MealEntry_foodId_idx" ON "MealEntry"("foodId");

ALTER TABLE "RefreshToken" ADD CONSTRAINT "RefreshToken_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "Dog" ADD CONSTRAINT "Dog_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "WeightEntry" ADD CONSTRAINT "WeightEntry_dogId_fkey" FOREIGN KEY ("dogId") REFERENCES "Dog"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "Food" ADD CONSTRAINT "Food_createdByUserId_fkey" FOREIGN KEY ("createdByUserId") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "Meal" ADD CONSTRAINT "Meal_dogId_fkey" FOREIGN KEY ("dogId") REFERENCES "Dog"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "MealEntry" ADD CONSTRAINT "MealEntry_mealId_fkey" FOREIGN KEY ("mealId") REFERENCES "Meal"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "MealEntry" ADD CONSTRAINT "MealEntry_foodId_fkey" FOREIGN KEY ("foodId") REFERENCES "Food"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
