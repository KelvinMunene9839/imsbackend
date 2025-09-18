-- Migration: Add document column to assets table

ALTER TABLE assets ADD COLUMN document VARCHAR(255);
