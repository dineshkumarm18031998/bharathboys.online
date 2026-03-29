-- ═══════════════════════════════════════════════════
-- KALYAN STORE - Database Tables
-- Run this SQL in Railway PostgreSQL → Data → Query
-- ═══════════════════════════════════════════════════

CREATE TABLE "Store" (
  "id" TEXT NOT NULL DEFAULT gen_random_uuid()::text,
  "storeName" TEXT NOT NULL,
  "ownerName" TEXT NOT NULL,
  "mobile" TEXT NOT NULL,
  "password" TEXT NOT NULL,
  "address" TEXT,
  "lang" TEXT NOT NULL DEFAULT 'en',
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "Store_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "Store_mobile_key" ON "Store"("mobile");

CREATE TABLE "Product" (
  "id" TEXT NOT NULL DEFAULT gen_random_uuid()::text,
  "name" TEXT NOT NULL,
  "totalQty" INTEGER NOT NULL,
  "rentPerDay" DOUBLE PRECISION NOT NULL,
  "deposit" DOUBLE PRECISION NOT NULL DEFAULT 0,
  "image" TEXT,
  "storeId" TEXT NOT NULL,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "Product_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "Product_storeId_idx" ON "Product"("storeId");

CREATE TABLE "Booking" (
  "id" TEXT NOT NULL DEFAULT gen_random_uuid()::text,
  "date" TEXT NOT NULL,
  "cName" TEXT NOT NULL,
  "cMob" TEXT NOT NULL,
  "cAddr" TEXT,
  "notes" TEXT,
  "eventType" TEXT,
  "startDate" TEXT NOT NULL,
  "returnDate" TEXT,
  "totalDays" INTEGER NOT NULL DEFAULT 0,
  "subtotal" DOUBLE PRECISION NOT NULL DEFAULT 0,
  "discount" DOUBLE PRECISION NOT NULL DEFAULT 0,
  "totalAmount" DOUBLE PRECISION NOT NULL DEFAULT 0,
  "paid" BOOLEAN NOT NULL DEFAULT false,
  "paidAmount" DOUBLE PRECISION NOT NULL DEFAULT 0,
  "returned" BOOLEAN NOT NULL DEFAULT false,
  "actualReturnDate" TEXT,
  "isVip" BOOLEAN NOT NULL DEFAULT false,
  "storeId" TEXT NOT NULL,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "Booking_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "Booking_storeId_idx" ON "Booking"("storeId");
CREATE INDEX "Booking_cMob_idx" ON "Booking"("cMob");

CREATE TABLE "BookingItem" (
  "id" TEXT NOT NULL DEFAULT gen_random_uuid()::text,
  "name" TEXT NOT NULL,
  "qty" INTEGER NOT NULL,
  "rate" DOUBLE PRECISION NOT NULL,
  "image" TEXT,
  "bookingId" TEXT NOT NULL,
  CONSTRAINT "BookingItem_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "BookingItem_bookingId_idx" ON "BookingItem"("bookingId");

CREATE TABLE "Damage" (
  "id" TEXT NOT NULL DEFAULT gen_random_uuid()::text,
  "product" TEXT NOT NULL,
  "qty" INTEGER NOT NULL,
  "rate" DOUBLE PRECISION NOT NULL,
  "bookingId" TEXT NOT NULL,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "Damage_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "Damage_bookingId_idx" ON "Damage"("bookingId");

ALTER TABLE "Product" ADD CONSTRAINT "Product_storeId_fkey" FOREIGN KEY ("storeId") REFERENCES "Store"("id") ON DELETE CASCADE;
ALTER TABLE "Booking" ADD CONSTRAINT "Booking_storeId_fkey" FOREIGN KEY ("storeId") REFERENCES "Store"("id") ON DELETE CASCADE;
ALTER TABLE "BookingItem" ADD CONSTRAINT "BookingItem_bookingId_fkey" FOREIGN KEY ("bookingId") REFERENCES "Booking"("id") ON DELETE CASCADE;
ALTER TABLE "Damage" ADD CONSTRAINT "Damage_bookingId_fkey" FOREIGN KEY ("bookingId") REFERENCES "Booking"("id") ON DELETE CASCADE;
