-- Fix surplus_allocations table (drop and recreate policies)
-- Run this if you get "already exists" errors

-- Drop existing policies
DROP POLICY IF EXISTS "Users can view own surplus allocations" ON surplus_allocations;
DROP POLICY IF EXISTS "Users can insert own surplus allocations" ON surplus_allocations;
DROP POLICY IF EXISTS "Users can update own surplus allocations" ON surplus_allocations;
DROP POLICY IF EXISTS "Users can delete own surplus allocations" ON surplus_allocations;

-- Add missing columns if they don't exist
ALTER TABLE surplus_allocations ADD COLUMN IF NOT EXISTS phase INTEGER DEFAULT 1;
ALTER TABLE surplus_allocations ADD COLUMN IF NOT EXISTS amount DECIMAL(12, 2);
ALTER TABLE surplus_allocations ADD COLUMN IF NOT EXISTS percentage DECIMAL(5, 2);
ALTER TABLE surplus_allocations ADD COLUMN IF NOT EXISTS icon TEXT DEFAULT '💰';
ALTER TABLE surplus_allocations ADD COLUMN IF NOT EXISTS description TEXT;
ALTER TABLE surplus_allocations ADD COLUMN IF NOT EXISTS order_index INTEGER DEFAULT 0;

-- Recreate RLS policies
CREATE POLICY "Users can view own surplus allocations"
  ON surplus_allocations FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own surplus allocations"
  ON surplus_allocations FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own surplus allocations"
  ON surplus_allocations FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own surplus allocations"
  ON surplus_allocations FOR DELETE
  USING (auth.uid() = user_id);

-- Create index if not exists
CREATE INDEX IF NOT EXISTS idx_surplus_allocations_user_phase ON surplus_allocations(user_id, phase);
