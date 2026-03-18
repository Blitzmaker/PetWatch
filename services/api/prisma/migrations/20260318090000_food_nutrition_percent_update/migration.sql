ALTER TABLE "Food"
  RENAME COLUMN "proteinPer100g" TO "proteinPercent";

ALTER TABLE "Food"
  RENAME COLUMN "fatPer100g" TO "fatPercent";

ALTER TABLE "Food"
  RENAME COLUMN "carbsPer100g" TO "crudeAshPercent";

ALTER TABLE "Food"
  ADD COLUMN "crudeFiberPercent" DOUBLE PRECISION;
