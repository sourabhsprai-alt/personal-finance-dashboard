# Finance Dashboard - Rebuild Specification

> **AI Regeneration Prompt**: Feed this document to an AI to recreate the core functionality of this personal finance dashboard. The AI should produce a working app with similar features, though implementation details may vary.

---

## Project Overview

Build a **personal finance dashboard** web app for tracking wealth across currencies and borders:

- **Multi-currency support** (EUR, INR, USD with live exchange rates)
- **Net worth tracking** (investments, savings, liabilities)
- **Liquid/Illiquid asset classification** (toggleable per asset)
- **Cash flow management** (income sources, monthly expenses separate from yearly)
- **Phase-based surplus allocation** (debt payoff → buffer → growth)
- **Fixed monthly investments** (SIPs, RDs - always active regardless of phase)
- **Goal progress tracking** with projections
- **Historical snapshots** for tracking progress over time

## Tech Stack

- **Frontend:** Vue 3 (Composition API)
- **Build:** Vite
- **Backend/Auth:** Supabase (PostgreSQL + Auth + Row Level Security)
- **Styling:** Custom CSS with CSS variables (dark theme, glassmorphism)
- **Charts:** vue-chartjs + Chart.js
- **PWA:** vite-plugin-pwa

## Design System

### Theme (Dark Mode with Glassmorphism)

```css
:root {
  --bg: #0f0f23;
  --bg-light: #1a1a2e;
  --bg-card: rgba(26, 26, 46, 0.8);
  --bg-glass: rgba(255, 255, 255, 0.03);
  --bg-elevated: rgba(255, 255, 255, 0.05);
  
  --text: #e4e4e7;
  --text-secondary: #a1a1aa;
  --text-muted: #71717a;
  
  --primary: #6366f1;
  --primary-dark: #4f46e5;
  --primary-light: #818cf8;
  
  --success: #10b981;
  --warning: #f59e0b;
  --danger: #ef4444;
  
  --border: rgba(255, 255, 255, 0.1);
}

.glass-card {
  background: var(--bg-card);
  backdrop-filter: blur(10px);
  border: 1px solid var(--border);
  border-radius: 16px;
}
```

### Typography
- Font: Inter (Google Fonts)
- Weights: 400, 500, 600, 700

## App Structure

```
src/
├── App.vue                 # Main app with auth + navigation
├── main.js                 # Vue app entry
├── lib/
│   └── supabase.js         # Supabase client
├── composables/
│   ├── useAuth.js          # Auth state & methods
│   └── useFinanceData.js   # All finance data & calculations
└── components/
    ├── Dashboard.vue       # Net worth overview, metrics, goals
    ├── Investments.vue     # Assets by category with liquid/illiquid toggle
    ├── Liabilities.vue     # Debts with APR, payments
    ├── CashFlow.vue        # Income + Monthly expenses (separate from yearly)
    ├── SurplusAllocation.vue # Phase-based allocation + fixed investments + checklist
    ├── Charts.vue          # Historical trends
    └── Settings.vue        # Exchange rates, targets, phases
```

## Features by Tab

### 1. Dashboard
- **Net Worth Hero Card** - Large display with dual currency (EUR/INR toggle)
- **Metrics Grid (2x2 on mobile, aligned heights):**
  - Crypto Exposure % (vs target) - calculated as crypto/total investments
  - Illiquid Assets % (vs target) - calculated as illiquid/total investments
  - Debt-to-Net-Worth Ratio (vs target)
  - Monthly Surplus amount
- **Investment Rules** - Color-coded reminder cards
- **Phase Progress** - Current goal with progress bar

### 2. Assets (Investments)
- Categories: India 🇮🇳, Germany 🇩🇪, Crypto 🪙, Savings 💰
- Each investment shows: name, amount, currency
- **Liquid/Illiquid toggle button** on each asset (💧 Liquid ↔ 🔒 Illiquid)
- Add/Edit/Delete investments
- Category totals with currency conversion

### 3. Debts (Liabilities)
- List all debts: name, amount, APR, minimum payment
- Total debt display
- Add/Edit/Delete liabilities

### 4. Cash Flow
- **Summary Cards:** Monthly Income | Monthly Expenses | Surplus
- **Income Sources Section:** List with name, amount, recurring tag
- **Monthly Expenses Section:**
  - Grouped by category (Housing, Utilities, Transport, Food, Insurance, Loans, Other)
  - **Hide empty categories** (categories with 0 expenses don't show)
  - Only shows monthly frequency items
- **Yearly & Quarterly Payments Section:**
  - Separate section for non-monthly expenses (NOT included in surplus calculation)
  - Shows total yearly cost + monthly equivalent for reference only
  - Frequency badges (yearly/quarterly)

### 5. Surplus Allocation (Clean, Action-Focused)

**Structure:**
1. **Overview Bar** - Income | Expenses | Gross Surplus + breakdown showing:
   - Gross Surplus
   - − Fixed Investments (in EUR)
   - = Available for Phase Goal (net surplus)
2. **Fixed Monthly Investments (📌)** - Always active regardless of phase
   - Recurring investments (SIPs, RDs, etc.)
   - **Editable:** Click Edit to modify amounts or add custom investments
   - Custom items stored as JSON for flexibility
   - Shows INR amounts with EUR equivalent
3. **Phase Allocations** - What to do with EUR surplus (after fixed investments)
   - **Phase selector dropdown** - edit allocations for any phase, not just current
   - Editable list with percentage or fixed amounts
   - Quick templates for Phase 1/2/3
   - Shows note when editing a different phase than current
4. **Goal Progress** - Phase-specific goal tracking
   - Phase 1: CC debt payoff focus
   - Phase 2: Buffer progress bar toward €15k
   - Phase 3: Wealth building breakdown
5. **Monthly Checklist** - Editable action items
   - **Check/uncheck items** with click
   - **Add custom items** via inline form
   - **Delete items** with hover-reveal × button
   - **Reset all** - uncheck everything for new month
   - **Auto-fill** - generate items from SIPs & allocations
   - Items tagged by category (sip/allocation/custom)
   - Checked items show strikethrough styling

**Phase Allocation Strategies:**
- **Phase 1:** 100% → Credit Card Debt (18% APR priority)
- **Phase 2:** 80% → Cash Buffer, 20% → COPX Investment
- **Phase 3:** €500 COPX, €400 Crash Fund, €250 Loan Prepay, €363 Flexible

### 6. Charts
- Line charts showing historical trends
- Net Worth over time
- Asset allocation changes

### 7. Settings
- **Phase Management:** Switch phases, view roadmap, update progress
- **Exchange Rates:** EUR↔INR, EUR↔USD (manual + live fetch from frankfurter.app)
- **Target Metrics:** Crypto %, Illiquid %, Debt ratio %, Emergency buffer
- **Single Save Button:** One "💾 Save All Settings" button for all changes

## Database Schema (Supabase)

### Tables

```sql
-- User settings & exchange rates
settings (
  id, user_id,
  eur_to_inr, eur_to_usd, usd_to_eur,
  target_crypto_exposure, target_illiquid_assets, 
  target_debt_to_networth, target_emergency_buffer,
  current_phase
  -- Note: Income now comes from income_sources table, not settings
)

-- Investments (with liquid/illiquid flag)
investments (
  id, user_id,
  category,      -- 'india', 'germany', 'crypto'
  name, amount, currency,
  is_illiquid,   -- toggleable in UI
  is_locked,
  invested_amount  -- cost basis for crypto
)

-- Savings accounts (always liquid)
savings (id, user_id, name, amount, currency)

-- Debts
liabilities (
  id, user_id,
  name, amount, currency,
  apr, min_payment
)

-- Dynamic income sources
income_sources (
  id, user_id,
  name, amount, currency,
  is_recurring
)

-- Dynamic expense items
expense_items (
  id, user_id,
  name, amount, currency,
  category,     -- housing, utilities, transport, food, insurance, loans, other
  frequency     -- monthly, quarterly, yearly (only monthly counted in surplus)
)

-- Fixed monthly investments (editable, always active)
indian_allocations (  -- table name kept for backwards compatibility
  id, user_id,
  ppfas_sourabh, ppfas_dhea, rd1, rd2,  -- amounts in INR (predefined investments)
  custom_sips  -- JSON array for user-added investments: [{name, amount, icon}, ...]
)

-- Surplus allocations (phase-specific)
surplus_allocations (
  id, user_id,
  phase,        -- 1, 2, or 3
  name, 
  amount,       -- fixed EUR amount (for Phase 3 style)
  percentage,   -- % of surplus (for Phase 1-2 style)
  icon, description,
  order_index
)

-- Goal phases
phase_progress (
  id, user_id,
  phase, name, target, current,
  is_complete
)

-- Investment reminder rules
investment_rules (id, user_id, text, color, order_index)

-- Monthly checklist items (editable)
checklist_items (
  id, user_id,
  name,         -- item text
  is_checked,   -- boolean toggle
  category,     -- 'sip', 'allocation', or 'custom'
  order_index,
  created_at
)

-- Historical snapshots
snapshots (
  id, user_id, snapshot_date,
  net_worth, total_investments, total_liabilities,
  crypto_total, illiquid_total,
  crypto_exposure_pct, illiquid_exposure_pct, debt_to_networth_pct
)
```

### Row Level Security
All tables have RLS enabled. Users can only CRUD their own data.

## Key Calculations (useFinanceData.js)

```javascript
// Currency conversion
convertToEUR(amount, currency) // Converts INR/USD to EUR
convertToINR(amount, currency) // Converts EUR/USD to INR

// Totals
getTotalInvestments  // Sum of investments + savings (in EUR)
getTotalLiabilities  // Sum of debts (in EUR)
getNetWorth          // Investments - Liabilities

// Exposure metrics (as % of TOTAL INVESTMENTS, not net worth)
getCryptoExposure    // (crypto total / total investments) * 100
getIlliquidExposure  // (illiquid total / total investments) * 100
getDebtToNetWorth    // (liabilities / net worth) * 100

// Cash flow (only monthly expenses counted)
getTotalMonthlyIncome   // Sum of income sources
getTotalMonthlyExpenses // Sum of expenses WHERE frequency = 'monthly'
getMonthlySurplus       // Income - Monthly Expenses (gross surplus)
getSavingsRate          // (surplus / income) * 100

// In SurplusAllocation.vue:
netSurplus              // Gross surplus - Fixed Investments (EUR) = what's available for phase goals

// Debt payoff calculations (in Liabilities component)
calculatePayoffMonths(debt, monthlyPayment) // Months to pay off at given payment
calculateInterestSaved(debt)                // Interest saved by using surplus
```

## Mobile Responsiveness

- **Dashboard metrics:** 2x2 grid with equal height cards, centered content
- **Navigation:** Icon-only tabs on mobile
- **Lists:** Stack vertically with full-width values
- **Forms:** Wrap inputs naturally

## Key UX Details

- **Consistent Page Banners:** All data tabs (Dashboard, Assets, Debts, Cash Flow, Surplus) use unified `.page-banner` styling with consistent padding, typography, and color accents
- **Liquid/Illiquid toggle:** Click button on any asset to switch (💧↔🔒)
- **Empty states:** Show helpful message when no data
- **Currency toggle:** Header button switches EUR ↔ INR display
- **Snapshot button:** 📸 in header saves current state to history
- **Phase templates:** Quick-apply allocation templates
- **Yearly expenses:** Shown for reference but NOT included in surplus calculation
- **Fixed Investments:** Always visible in Surplus tab, regardless of phase; editable with ability to add custom items
- **Monthly Checklist:** Fully editable - check/uncheck, add custom items, delete items, reset all, auto-fill from SIPs & allocations
- **Savings Rate:** Displayed on Dashboard as % of income being saved
- **Debt Payoff Calculator:** Each debt shows months to payoff and interest saved
- **Auto Exchange Rates:** Fetches daily from frankfurter.app on app load

## Environment Variables

```
VITE_SUPABASE_URL=https://xxx.supabase.co
VITE_SUPABASE_ANON_KEY=xxx
```

## SQL Files to Run (in order)

1. `supabase-schema.sql` - Main schema with all tables
2. `fix-surplus-allocations.sql` - Surplus allocations table with phase support
3. `add-checklist.sql` - Checklist items table for monthly tracking

## Deployment

1. Create Supabase project
2. Run SQL files in Supabase SQL Editor (in order)
3. Set environment variables
4. `npm install && npm run build`
5. Deploy `dist/` folder to Netlify/Vercel

## Regeneration Instructions

To rebuild this project from scratch:

1. Create Vite + Vue 3 project: `npm create vite@latest finance-dashboard -- --template vue`
2. Install dependencies:
   ```
   npm install @supabase/supabase-js vue-chartjs chart.js
   npm install -D vite-plugin-pwa
   ```
3. Set up Supabase project and run SQL schemas
4. Create the composables (useAuth.js, useFinanceData.js)
5. Build components following the structure above
6. Apply the dark glassmorphism theme
7. Test auth flow and CRUD operations
8. Verify calculations (especially illiquid % and monthly surplus)

## Design Philosophy

- **Action-oriented:** Focus on "what to do now" not historical analysis
- **Phase-driven:** Different strategies for different financial phases
- **Fixed investments are sacred:** They continue regardless of phase
- **Simplicity over features:** No monthly history tracking (snapshots handle that)
- **Mobile-first:** Works well on phone for quick checks
- **Subtle, modern styling:** Avoid loud gradients; use muted backgrounds with colored accent borders instead of bold banner colors
