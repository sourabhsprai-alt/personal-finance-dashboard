-- Add ESOP fields to investments table
-- Run this in Supabase SQL Editor

ALTER TABLE investments 
ADD COLUMN IF NOT EXISTS esop_total_shares INTEGER DEFAULT NULL,
ADD COLUMN IF NOT EXISTS esop_vested_shares INTEGER DEFAULT NULL,
ADD COLUMN IF NOT EXISTS esop_share_value DECIMAL(10, 4) DEFAULT NULL;

-- For ESOP investments, the 'amount' field will be auto-calculated as:
-- esop_vested_shares * esop_share_value
