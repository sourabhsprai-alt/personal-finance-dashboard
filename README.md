# 💰 Personal Finance Dashboard

A cloud-backed progressive web app (PWA) for tracking investments, liabilities, and financial goals across multiple currencies with multi-device sync.

## ✨ Features

- 📊 **Dashboard** — Net worth overview, key metrics, goal progress
- 💎 **Investments** — Track assets across regions and asset types
- 💳 **Liabilities** — Manage debts with APR and payoff calculations
- 💸 **Cash Flow** — Income and expense tracking
- 🎯 **Surplus Allocation** — Phase-based financial goal planning
- 📈 **Charts** — Historical net worth tracking
- 🔐 **Authentication** — Secure login with email/password
- ☁️ **Cloud Sync** — Supabase backend with Row Level Security
- 📱 **PWA** — Install as mobile app, works offline
- 🙈 **Privacy Mode** — Hide values with one tap
- ⏱️ **Auto-logout** — Session timeout for security

## 🛠️ Tech Stack

- **Frontend:** Vue 3 + Vite
- **Backend:** Supabase (PostgreSQL + Auth)
- **Charts:** Chart.js
- **PWA:** Vite PWA plugin
- **Hosting:** Netlify

## 🚀 Setup

### 1. Clone and install

```bash
git clone https://github.com/YOUR_USERNAME/personal-finance-dashboard.git
cd personal-finance-dashboard
npm install
```

### 2. Configure Supabase

1. Create a project at [supabase.com](https://supabase.com)
2. Run `supabase-schema.sql` in the SQL Editor
3. Update `src/lib/supabase.js` with your project URL and anon key

### 3. Run locally

```bash
npm run dev
```

### 4. Build for production

```bash
npm run build
```

## 📱 Install as App

**iOS:** Safari → Share → Add to Home Screen  
**Android:** Chrome → Menu → Install App

## 🔒 Security

- Row Level Security ensures users only see their own data
- Session auto-expires after inactivity
- All data encrypted in transit (HTTPS)

## 📄 License

MIT — use freely, modify as needed.
