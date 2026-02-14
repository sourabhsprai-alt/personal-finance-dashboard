# 💰 Personal Finance Dashboard (Cloud Edition)

A cloud-backed progressive web app (PWA) for tracking investments, liabilities, and financial goals across multiple currencies (EUR, INR, USD) with multi-device sync.

## ✨ Features

- 📊 **Dashboard** - Key metrics, goal progress, investment rules with color-coded targets
- 💰 **Investments** - Track assets in India, Germany, crypto, and savings (all editable)
- 📉 **Liabilities** - Manage loans with APR and payoff calculations
- 💸 **Cash Flow** - Phase-based monthly allocation tracking
- 📈 **Charts** - Historical net worth tracking over time
- ⚙️ **Settings** - Editable rates, targets, income adjustments
- 🔐 **Authentication** - Secure login with email/password
- ☁️ **Cloud Storage** - Supabase PostgreSQL backend with Row Level Security
- 📱 **PWA Support** - Install as mobile app ("Add to Home Screen")
- 🌐 **Multi-device Sync** - Access from anywhere
- 🔒 **Private** - Your data is encrypted and only you can access it

## 🚀 Quick Start

### 1. Database Setup

**Run the schema in Supabase SQL Editor:**

1. Go to your Supabase project: https://wensfyzuxzbdyxlpusij.supabase.co
2. Navigate to **SQL Editor**
3. Copy the contents of `supabase-schema.sql`
4. Paste and **Run** the SQL

This will create:
- All necessary tables (settings, investments, liabilities, etc.)
- Row Level Security policies (users can only see their own data)
- Functions for snapshots and auto-updates

### 2. Install Dependencies

```bash
npm install
```

### 3. Run Development Server

```bash
npm run dev
```

Open http://localhost:5173

### 4. Create Account

1. Click **Sign Up**
2. Enter email and password
3. Check your email for verification (Supabase sends confirmation)
4. Sign in with your credentials

Your account will be pre-populated with default data (you can edit everything).

## 📸 Daily Snapshots

Click the **📸** button in the header to save a snapshot of your current net worth. This creates a data point for the **Charts** tab to show your financial progress over time.

**Tip:** Create a snapshot daily/weekly/monthly to track trends!

## 💾 Data Management

### Your Data is Safe

- Stored in Supabase PostgreSQL (encrypted at rest)
- Row Level Security ensures only you can access your data
- Backed up automatically by Supabase
- Multi-region redundancy

### Export Data (Optional)

While your data is in the cloud, you can still export from the **Settings** tab for local backups.

## 🔧 Configuration

### Exchange Rates

Go to **Settings → Exchange Rates** and click **Fetch Live Rates** to update from Frankfurter API (EU Central Bank data, free).

Or manually edit rates if you prefer fixed values for planning.

### Target Metrics

Adjust your target metrics in **Settings**:
- **Crypto Exposure** - Default: 35% (aggressive)
- **Illiquid Assets** - Default: 40% (includes property + ESOPs)
- **Debt-to-Net-Worth** - Default: 30% (comfortable leverage)
- **Emergency Buffer** - Default: €15,000

These targets show color-coded indicators (🟢 🟡 🔴) on the Dashboard.

### Income Adjustments

When your child arrives, update in **Settings**:
- **Kindergeld**: 300 EUR/month
- **Upasana Govt Support**: 250 EUR/month (first year only)

## 📊 Phase System

Your financial journey is divided into phases:

### Phase 1: Clear Credit Card
- Target: €2,100
- Priority: Pay off high-interest debt (18% APR)

### Phase 2: Build Emergency Buffer
- Target: €15,000
- Allocation: €1,400/month to buffer + €150 to COPX

### Phase 3: Aggressive Growth
- Allocations:
  - €500/month → COPX ETF
  - €400/month → Crash fund (liquid opportunities)
  - €250/month → Personal loan prepay
  - €363/month → Flexible buffer

Update phase progress in the **Investments** or **Settings** tab.

## 🌍 Multi-Currency Support

All investments are stored in their native currency (INR, EUR, USD) and converted in real-time using exchange rates.

**Toggle Display Currency:**  
Use the EUR/INR toggle in the header to switch between viewing everything in Euros or Indian Rupees.

## 📱 Install as App

### iOS (Safari)
1. Tap the **Share** button
2. Select **Add to Home Screen**
3. Tap **Add**

### Android (Chrome)
1. Tap the menu (⋮)
2. Select **Install app** or **Add to Home Screen**

## 🔒 Security

- **Row Level Security (RLS)**: PostgreSQL policies ensure users can only access their own data
- **Authentication**: Supabase Auth with email verification
- **HTTPS**: All data transmitted over secure connections
- **API Keys**: Anon key is safe to expose (RLS prevents unauthorized access)

## 🛠️ Tech Stack

- **Frontend**: Vue 3 + Vite
- **Backend**: Supabase (PostgreSQL + Auth)
- **Charts**: Chart.js + vue-chartjs
- **PWA**: Vite PWA plugin
- **Styling**: Custom CSS with dark theme

## 🚀 Deployment

### Build for Production

```bash
npm run build
```

The `dist/` folder can be deployed to:

### Option 1: Netlify (Recommended)
1. Drag & drop `dist/` to https://app.netlify.com/drop
2. Or connect GitHub repo

### Option 2: Vercel
```bash
npm install -g vercel
vercel --prod
```

### Option 3: GitHub Pages
```bash
# Push dist/ to gh-pages branch
```

### Environment Variables

The Supabase credentials are hardcoded in `src/lib/supabase.js`. For production, consider using environment variables:

```js
const supabaseUrl = import.meta.env.VITE_SUPABASE_URL
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY
```

## 📈 Roadmap

- [x] Cloud storage with Supabase
- [x] Authentication & multi-device sync
- [x] Historical snapshots
- [x] Charts for net worth tracking
- [ ] Automatic daily snapshots (cron job)
- [ ] Budget vs actual tracking
- [ ] Transaction logging
- [ ] Mobile app (React Native)
- [ ] Export to CSV/Excel
- [ ] Family sharing (optional)

## 🤝 Contributing

This is a personal project, but feel free to fork and customize for your own use!

## 📄 License

MIT License - Use freely!

---

Built with ❤️ for tracking wealth across borders 🌍
