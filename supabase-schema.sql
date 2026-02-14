-- Finance Dashboard Database Schema
-- Run this in Supabase SQL Editor

-- Enable Row Level Security
ALTER DATABASE postgres SET "app.jwt_secret" TO 'your-jwt-secret';

-- User Profiles (extends auth.users)
CREATE TABLE user_profiles (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  email TEXT,
  full_name TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Settings (exchange rates, targets, income)
CREATE TABLE settings (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  
  -- Exchange rates
  eur_to_inr DECIMAL(10, 4) DEFAULT 107.58,
  eur_to_usd DECIMAL(10, 4) DEFAULT 1.04,
  usd_to_eur DECIMAL(10, 4) DEFAULT 0.96,
  
  -- Target metrics
  target_crypto_exposure DECIMAL(5, 2) DEFAULT 35,
  target_illiquid_assets DECIMAL(5, 2) DEFAULT 40,
  target_debt_to_networth DECIMAL(5, 2) DEFAULT 30,
  target_emergency_buffer DECIMAL(12, 2) DEFAULT 15000,
  
  -- Income
  base_income DECIMAL(12, 2) DEFAULT 5312,
  kindergeld DECIMAL(12, 2) DEFAULT 0,
  upasana_govt DECIMAL(12, 2) DEFAULT 0,
  
  -- Current phase
  current_phase INTEGER DEFAULT 1,
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  UNIQUE(user_id)
);

-- Expenses
CREATE TABLE expenses (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  
  rent DECIMAL(12, 2) DEFAULT 1276.76,
  parking DECIMAL(12, 2) DEFAULT 55,
  phone DECIMAL(12, 2) DEFAULT 15,
  internet DECIMAL(12, 2) DEFAULT 65,
  electricity DECIMAL(12, 2) DEFAULT 76,
  groceries DECIMAL(12, 2) DEFAULT 400,
  upasana DECIMAL(12, 2) DEFAULT 250,
  car_loan_min DECIMAL(12, 2) DEFAULT 430,
  personal_loan_min DECIMAL(12, 2) DEFAULT 509,
  car_insurance_monthly DECIMAL(12, 2) DEFAULT 72.33,
  legal_insurance_monthly DECIMAL(12, 2) DEFAULT 29.17,
  lohi_monthly DECIMAL(12, 2) DEFAULT 22.75,
  eating_out DECIMAL(12, 2) DEFAULT 250,
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  UNIQUE(user_id)
);

-- Indian Allocations
CREATE TABLE indian_allocations (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  
  ppfas_sourabh DECIMAL(12, 2) DEFAULT 11000,
  ppfas_dhea DECIMAL(12, 2) DEFAULT 1500,
  rd1 DECIMAL(12, 2) DEFAULT 10000,
  rd2 DECIMAL(12, 2) DEFAULT 5000,
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  UNIQUE(user_id)
);

-- Investments
CREATE TABLE investments (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  
  category TEXT NOT NULL, -- 'india', 'germany', 'crypto'
  name TEXT NOT NULL,
  amount DECIMAL(18, 2) NOT NULL,
  currency TEXT NOT NULL, -- 'INR', 'EUR', 'USD'
  is_illiquid BOOLEAN DEFAULT FALSE,
  is_locked BOOLEAN DEFAULT FALSE,
  invested_amount DECIMAL(18, 2), -- For crypto tracking cost basis
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Savings
CREATE TABLE savings (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  
  name TEXT NOT NULL,
  amount DECIMAL(18, 2) NOT NULL,
  currency TEXT NOT NULL,
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Liabilities
CREATE TABLE liabilities (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  
  name TEXT NOT NULL,
  amount DECIMAL(18, 2) NOT NULL,
  currency TEXT NOT NULL,
  apr DECIMAL(5, 2) NOT NULL,
  min_payment DECIMAL(12, 2) NOT NULL,
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Phase Progress
CREATE TABLE phase_progress (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  
  phase INTEGER NOT NULL,
  name TEXT NOT NULL,
  target DECIMAL(12, 2),
  current DECIMAL(12, 2) DEFAULT 0,
  is_complete BOOLEAN DEFAULT FALSE,
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  UNIQUE(user_id, phase)
);

-- Investment Rules
CREATE TABLE investment_rules (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  
  text TEXT NOT NULL,
  color TEXT NOT NULL,
  order_index INTEGER DEFAULT 0,
  
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Historical Snapshots (for charts and tracking)
CREATE TABLE snapshots (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  
  snapshot_date DATE NOT NULL,
  net_worth DECIMAL(18, 2) NOT NULL,
  total_investments DECIMAL(18, 2) NOT NULL,
  total_liabilities DECIMAL(18, 2) NOT NULL,
  crypto_total DECIMAL(18, 2) NOT NULL,
  illiquid_total DECIMAL(18, 2) NOT NULL,
  
  crypto_exposure_pct DECIMAL(5, 2),
  illiquid_exposure_pct DECIMAL(5, 2),
  debt_to_networth_pct DECIMAL(5, 2),
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  
  UNIQUE(user_id, snapshot_date)
);

-- Enable Row Level Security on all tables
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE indian_allocations ENABLE ROW LEVEL SECURITY;
ALTER TABLE investments ENABLE ROW LEVEL SECURITY;
ALTER TABLE savings ENABLE ROW LEVEL SECURITY;
ALTER TABLE liabilities ENABLE ROW LEVEL SECURITY;
ALTER TABLE phase_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE investment_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE snapshots ENABLE ROW LEVEL SECURITY;

-- RLS Policies: Users can only access their own data

-- user_profiles
CREATE POLICY "Users can view own profile" ON user_profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON user_profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users can insert own profile" ON user_profiles FOR INSERT WITH CHECK (auth.uid() = id);

-- settings
CREATE POLICY "Users can view own settings" ON settings FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can update own settings" ON settings FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own settings" ON settings FOR INSERT WITH CHECK (auth.uid() = user_id);

-- expenses
CREATE POLICY "Users can view own expenses" ON expenses FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can update own expenses" ON expenses FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own expenses" ON expenses FOR INSERT WITH CHECK (auth.uid() = user_id);

-- indian_allocations
CREATE POLICY "Users can view own allocations" ON indian_allocations FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can update own allocations" ON indian_allocations FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own allocations" ON indian_allocations FOR INSERT WITH CHECK (auth.uid() = user_id);

-- investments
CREATE POLICY "Users can view own investments" ON investments FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can update own investments" ON investments FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own investments" ON investments FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete own investments" ON investments FOR DELETE USING (auth.uid() = user_id);

-- savings
CREATE POLICY "Users can view own savings" ON savings FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can update own savings" ON savings FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own savings" ON savings FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete own savings" ON savings FOR DELETE USING (auth.uid() = user_id);

-- liabilities
CREATE POLICY "Users can view own liabilities" ON liabilities FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can update own liabilities" ON liabilities FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own liabilities" ON liabilities FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete own liabilities" ON liabilities FOR DELETE USING (auth.uid() = user_id);

-- phase_progress
CREATE POLICY "Users can view own phase progress" ON phase_progress FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can update own phase progress" ON phase_progress FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own phase progress" ON phase_progress FOR INSERT WITH CHECK (auth.uid() = user_id);

-- investment_rules
CREATE POLICY "Users can view own rules" ON investment_rules FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can update own rules" ON investment_rules FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own rules" ON investment_rules FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete own rules" ON investment_rules FOR DELETE USING (auth.uid() = user_id);

-- snapshots
CREATE POLICY "Users can view own snapshots" ON snapshots FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own snapshots" ON snapshots FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Function to create snapshot
CREATE OR REPLACE FUNCTION create_snapshot(p_user_id UUID)
RETURNS UUID AS $$
DECLARE
  v_snapshot_id UUID;
  v_net_worth DECIMAL(18, 2);
  v_total_investments DECIMAL(18, 2);
  v_total_liabilities DECIMAL(18, 2);
  v_crypto_total DECIMAL(18, 2);
  v_illiquid_total DECIMAL(18, 2);
BEGIN
  -- Calculate totals (you'll need to implement currency conversion in app)
  SELECT COALESCE(SUM(amount), 0) INTO v_total_investments 
  FROM investments WHERE user_id = p_user_id;
  
  SELECT COALESCE(SUM(amount), 0) INTO v_total_liabilities
  FROM liabilities WHERE user_id = p_user_id;
  
  SELECT COALESCE(SUM(amount), 0) INTO v_crypto_total
  FROM investments WHERE user_id = p_user_id AND category = 'crypto';
  
  SELECT COALESCE(SUM(amount), 0) INTO v_illiquid_total
  FROM investments WHERE user_id = p_user_id AND is_illiquid = TRUE;
  
  v_net_worth := v_total_investments - v_total_liabilities;
  
  INSERT INTO snapshots (
    user_id, 
    snapshot_date, 
    net_worth, 
    total_investments, 
    total_liabilities,
    crypto_total,
    illiquid_total
  ) VALUES (
    p_user_id,
    CURRENT_DATE,
    v_net_worth,
    v_total_investments,
    v_total_liabilities,
    v_crypto_total,
    v_illiquid_total
  )
  ON CONFLICT (user_id, snapshot_date) 
  DO UPDATE SET
    net_worth = EXCLUDED.net_worth,
    total_investments = EXCLUDED.total_investments,
    total_liabilities = EXCLUDED.total_liabilities,
    crypto_total = EXCLUDED.crypto_total,
    illiquid_total = EXCLUDED.illiquid_total,
    updated_at = NOW()
  RETURNING id INTO v_snapshot_id;
  
  RETURN v_snapshot_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers for updated_at
CREATE TRIGGER update_settings_updated_at BEFORE UPDATE ON settings
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_expenses_updated_at BEFORE UPDATE ON expenses
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_indian_allocations_updated_at BEFORE UPDATE ON indian_allocations
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_investments_updated_at BEFORE UPDATE ON investments
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_savings_updated_at BEFORE UPDATE ON savings
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_liabilities_updated_at BEFORE UPDATE ON liabilities
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_phase_progress_updated_at BEFORE UPDATE ON phase_progress
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
