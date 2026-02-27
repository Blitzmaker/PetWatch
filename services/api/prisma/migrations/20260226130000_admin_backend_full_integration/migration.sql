-- CreateEnum
CREATE TYPE "UserRole" AS ENUM ('USER', 'MODERATOR', 'CURATOR', 'FOOD_REVIEWER', 'ADMIN');

-- CreateEnum
CREATE TYPE "FoodStatus" AS ENUM ('DRAFT_LOCAL', 'PENDING_REVIEW', 'APPROVED_PUBLIC', 'REJECTED');

-- CreateEnum
CREATE TYPE "PublicationStatus" AS ENUM ('DRAFT', 'PUBLISHED', 'ARCHIVED');

-- AlterTable
ALTER TABLE "User"
ADD COLUMN "role" "UserRole" NOT NULL DEFAULT 'USER',
ADD COLUMN "isBlocked" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN "deletedAt" TIMESTAMP(3);

-- AlterTable
ALTER TABLE "Food"
ADD COLUMN "status" "FoodStatus" NOT NULL DEFAULT 'DRAFT_LOCAL',
ADD COLUMN "reviewedByAdminId" TEXT,
ADD COLUMN "reviewComment" TEXT,
ADD COLUMN "approvedAt" TIMESTAMP(3);

-- CreateTable
CREATE TABLE "CmsCategory" (
    "id" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "slug" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "CmsCategory_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "CmsPost" (
    "id" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "slug" TEXT NOT NULL,
    "teaser" TEXT,
    "content" TEXT NOT NULL,
    "status" "PublicationStatus" NOT NULL DEFAULT 'DRAFT',
    "publishedAt" TIMESTAMP(3),
    "authorId" TEXT NOT NULL,
    "categoryId" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "CmsPost_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "CommunityTopic" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT,
    "status" "PublicationStatus" NOT NULL DEFAULT 'PUBLISHED',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "CommunityTopic_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "CommunityThread" (
    "id" TEXT NOT NULL,
    "topicId" TEXT NOT NULL,
    "authorId" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "content" TEXT NOT NULL,
    "status" "PublicationStatus" NOT NULL DEFAULT 'PUBLISHED',
    "isLocked" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "CommunityThread_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "CommunityPost" (
    "id" TEXT NOT NULL,
    "threadId" TEXT NOT NULL,
    "authorId" TEXT NOT NULL,
    "content" TEXT NOT NULL,
    "status" "PublicationStatus" NOT NULL DEFAULT 'PUBLISHED',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "CommunityPost_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "CmsCategory_title_key" ON "CmsCategory"("title");

-- CreateIndex
CREATE UNIQUE INDEX "CmsCategory_slug_key" ON "CmsCategory"("slug");

-- CreateIndex
CREATE UNIQUE INDEX "CmsPost_slug_key" ON "CmsPost"("slug");

-- CreateIndex
CREATE INDEX "CmsPost_status_publishedAt_idx" ON "CmsPost"("status", "publishedAt");

-- CreateIndex
CREATE UNIQUE INDEX "CommunityTopic_name_key" ON "CommunityTopic"("name");

-- CreateIndex
CREATE INDEX "CommunityThread_topicId_createdAt_idx" ON "CommunityThread"("topicId", "createdAt");

-- CreateIndex
CREATE INDEX "CommunityPost_threadId_createdAt_idx" ON "CommunityPost"("threadId", "createdAt");

-- AddForeignKey
ALTER TABLE "Food" ADD CONSTRAINT "Food_reviewedByAdminId_fkey" FOREIGN KEY ("reviewedByAdminId") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "CmsPost" ADD CONSTRAINT "CmsPost_authorId_fkey" FOREIGN KEY ("authorId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "CmsPost" ADD CONSTRAINT "CmsPost_categoryId_fkey" FOREIGN KEY ("categoryId") REFERENCES "CmsCategory"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "CommunityThread" ADD CONSTRAINT "CommunityThread_topicId_fkey" FOREIGN KEY ("topicId") REFERENCES "CommunityTopic"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "CommunityThread" ADD CONSTRAINT "CommunityThread_authorId_fkey" FOREIGN KEY ("authorId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "CommunityPost" ADD CONSTRAINT "CommunityPost_threadId_fkey" FOREIGN KEY ("threadId") REFERENCES "CommunityThread"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "CommunityPost" ADD CONSTRAINT "CommunityPost_authorId_fkey" FOREIGN KEY ("authorId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
