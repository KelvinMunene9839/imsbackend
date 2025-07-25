-- Migration to add imageUrl column to investors table
ALTER TABLE investors ADD COLUMN imageUrl VARCHAR(255) NULL;
