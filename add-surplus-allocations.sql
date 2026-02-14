-- Surplus Allocations Table (Phase-based, editable line items)
-- Run this in Supabase SQL Editor

CREATE TABLE IF NOT EXISTS surplus_allocations (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  phase INTEGER NOT NULL DEFAULT 1,
  name TEXT NOT NULL,
  amount DECIMAL(12, 2),           -- Fixed EUR amount (for Phase 3 style)
  percentage DECIMAL(5, 2),        -- Percentage of surplus (for Phase 1-2 style)
  icon TEXT DEFAULT '💰',
  description TEXT,
  order_index INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE surplus_allocations ENABLE ROW LEVEL SECURITY;

-- RLS Policies
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

-- Index
CREATE INDEX idx_surplus_allocations_user_phase ON surplus_allocations(user_id, phase);

-- Trigger for updated_at
CREATE TRIGGER update_surplus_allocations_updated_at 
  BEFORE UPDATE ON surplus_allocations
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
