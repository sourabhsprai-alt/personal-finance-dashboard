-- Add one_time_expenses column to indian_allocations table
-- Run this in Supabase SQL Editor

ALTER TABLE indian_allocations 
ADD COLUMN IF NOT EXISTS one_time_expenses JSONB DEFAULT '[]';

-- Example data format:
-- [{"name": "Car repair", "amount": 500, "icon": "🚗"}, {"name": "Flight", "amount": 300, "icon": "✈️"}]
