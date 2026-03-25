-- CreateEnum
CREATE TYPE "NewsReactionType" AS ENUM ('LIKE', 'LOVE', 'LAUGH', 'WOW', 'SAD');

-- CreateTable
CREATE TABLE "NewsReaction" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "newsPostId" TEXT NOT NULL,
    "reaction" "NewsReactionType" NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "NewsReaction_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "NewsReaction_newsPostId_idx" ON "NewsReaction"("newsPostId");

-- CreateIndex
CREATE UNIQUE INDEX "NewsReaction_userId_newsPostId_key" ON "NewsReaction"("userId", "newsPostId");

-- AddForeignKey
ALTER TABLE "NewsReaction" ADD CONSTRAINT "NewsReaction_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
