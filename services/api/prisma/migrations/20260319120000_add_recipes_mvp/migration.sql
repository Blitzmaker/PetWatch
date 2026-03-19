CREATE TYPE "RecipeVisibility" AS ENUM ('PRIVATE');

CREATE TABLE "Recipe" (
  "id" TEXT NOT NULL,
  "createdByUserId" TEXT NOT NULL,
  "title" TEXT NOT NULL,
  "description" TEXT,
  "visibility" "RecipeVisibility" NOT NULL DEFAULT 'PRIVATE',
  "defaultPortions" DOUBLE PRECISION,
  "yieldTotalGrams" DOUBLE PRECISION NOT NULL,
  "notes" TEXT,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL,
  CONSTRAINT "Recipe_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "RecipeItem" (
  "id" TEXT NOT NULL,
  "recipeId" TEXT NOT NULL,
  "foodId" TEXT NOT NULL,
  "grams" DOUBLE PRECISION NOT NULL,
  "sortOrder" INTEGER NOT NULL,
  CONSTRAINT "RecipeItem_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "RecipeStep" (
  "id" TEXT NOT NULL,
  "recipeId" TEXT NOT NULL,
  "sortOrder" INTEGER NOT NULL,
  "title" TEXT,
  "instruction" TEXT NOT NULL,
  CONSTRAINT "RecipeStep_pkey" PRIMARY KEY ("id")
);

ALTER TABLE "MealEntry"
  ADD COLUMN "sourceRecipeId" TEXT,
  ADD COLUMN "sourceRecipeTitleSnapshot" TEXT;

CREATE INDEX "Recipe_createdByUserId_createdAt_idx" ON "Recipe"("createdByUserId", "createdAt");
CREATE INDEX "RecipeItem_recipeId_sortOrder_idx" ON "RecipeItem"("recipeId", "sortOrder");
CREATE INDEX "RecipeItem_foodId_idx" ON "RecipeItem"("foodId");
CREATE INDEX "RecipeStep_recipeId_sortOrder_idx" ON "RecipeStep"("recipeId", "sortOrder");
CREATE INDEX "MealEntry_sourceRecipeId_idx" ON "MealEntry"("sourceRecipeId");

ALTER TABLE "Recipe"
  ADD CONSTRAINT "Recipe_createdByUserId_fkey" FOREIGN KEY ("createdByUserId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "RecipeItem"
  ADD CONSTRAINT "RecipeItem_recipeId_fkey" FOREIGN KEY ("recipeId") REFERENCES "Recipe"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "RecipeItem"
  ADD CONSTRAINT "RecipeItem_foodId_fkey" FOREIGN KEY ("foodId") REFERENCES "Food"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "RecipeStep"
  ADD CONSTRAINT "RecipeStep_recipeId_fkey" FOREIGN KEY ("recipeId") REFERENCES "Recipe"("id") ON DELETE CASCADE ON UPDATE CASCADE;
