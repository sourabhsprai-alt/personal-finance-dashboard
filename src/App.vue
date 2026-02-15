<template>
  <div id="app">
    <!-- Loading State -->
    <div v-if="authLoading" class="loading-screen">
      <div class="loader"></div>
      <p>Loading...</p>
    </div>

    <!-- Auth Screen -->
    <div v-else-if="!isAuthenticated" class="auth-screen">
      <div class="auth-card glass-card">
        <div class="auth-header">
          <h1>Finance Dashboard</h1>
          <p>Track your wealth across currencies & borders</p>
        </div>

        <div class="auth-tabs">
          <button :class="{ active: authMode === 'signin' }" @click="authMode = 'signin'">Sign In</button>
          <button :class="{ active: authMode === 'signup' }" @click="authMode = 'signup'">Sign Up</button>
        </div>

        <form @submit.prevent="handleAuth" class="auth-form">
          <div class="input-group">
            <label>Email</label>
            <input type="email" v-model="email" placeholder="your@email.com" required />
          </div>
          <div class="input-group">
            <label>Password</label>
            <input type="password" v-model="password" placeholder="••••••••" required minlength="6" />
          </div>
          <div v-if="authError" class="error-msg">{{ authError }}</div>
          <button type="submit" class="btn-primary btn-full" :disabled="authSubmitting">
            {{ authSubmitting ? 'Please wait...' : (authMode === 'signin' ? 'Sign In' : 'Create Account') }}
          </button>
        </form>
      </div>
    </div>

    <!-- Main App -->
    <div v-else class="app-container">
      <header class="app-header glass-card">
        <div class="header-left">
          <h1>Finance</h1>
        </div>
        <div class="header-right">
          <div class="currency-switch">
            <button :class="{ active: displayCurrency === 'EUR' }" @click="displayCurrency = 'EUR'">€</button>
            <button :class="{ active: displayCurrency === 'INR' }" @click="displayCurrency = 'INR'">₹</button>
          </div>
          <button @click="toggleValuesHidden" class="btn-icon" :title="valuesHidden ? 'Show Values' : 'Hide Values'">
            {{ valuesHidden ? '🙈' : '👁️' }}
          </button>
          <button @click="handleSnapshot" class="btn-icon" title="Save Snapshot">📸</button>
          <button @click="handleSignOut" class="btn-ghost">Sign Out</button>
        </div>
      </header>

      <nav class="app-nav">
        <button 
          v-for="tab in tabs" 
          :key="tab.id"
          :class="{ active: currentTab === tab.id }"
          @click="currentTab = tab.id"
        >
          <span class="nav-icon">{{ tab.icon }}</span>
          <span class="nav-label">{{ tab.name }}</span>
        </button>
      </nav>

      <main class="app-main">
        <div v-if="dataLoading" class="loading-content">
          <div class="loader"></div>
        </div>
        <component v-else :is="currentComponent" :display-currency="displayCurrency" :values-hidden="valuesHidden" />
      </main>
    </div>
  </div>
</template>

<script>
import { ref, computed, onMounted } from 'vue'
import { useAuth } from './composables/useAuth'
import { useFinanceData } from './composables/useFinanceData'
import Dashboard from './components/Dashboard.vue'
import Investments from './components/Investments.vue'
import Liabilities from './components/Liabilities.vue'
import CashFlow from './components/CashFlow.vue'
import SurplusAllocation from './components/SurplusAllocation.vue'
import Charts from './components/Charts.vue'
import Settings from './components/Settings.vue'

export default {
  name: 'App',
  components: { Dashboard, Investments, Liabilities, CashFlow, SurplusAllocation, Charts, Settings },
  setup() {
    const { user, loading: authLoading, isAuthenticated, initialize, signIn, signUp, signOut } = useAuth()
    const { fetchAllData, loading: dataLoading, createSnapshot } = useFinanceData()

    const currentTab = ref('dashboard')
    const displayCurrency = ref('EUR')
    const valuesHidden = ref(localStorage.getItem('valuesHidden') !== 'false') // Default: hidden
    const lastActivity = ref(Date.now())
    const SESSION_TIMEOUT = 10 * 60 * 1000 // 10 minutes
    const authMode = ref('signin')
    const email = ref('')
    const password = ref('')
    const authError = ref('')
    const authSubmitting = ref(false)

    const tabs = [
      { id: 'dashboard', name: 'Dashboard', icon: '📊' },
      { id: 'investments', name: 'Assets', icon: '💎' },
      { id: 'liabilities', name: 'Debts', icon: '💳' },
      { id: 'cashflow', name: 'Cash Flow', icon: '💸' },
      { id: 'surplus', name: 'Surplus', icon: '🎯' },
      { id: 'charts', name: 'Charts', icon: '📈' },
      { id: 'settings', name: 'Settings', icon: '⚙️' }
    ]

    const currentComponent = computed(() => {
      return { dashboard: 'Dashboard', investments: 'Investments', liabilities: 'Liabilities', cashflow: 'CashFlow', surplus: 'SurplusAllocation', charts: 'Charts', settings: 'Settings' }[currentTab.value]
    })

    const handleAuth = async () => {
      authError.value = ''
      authSubmitting.value = true
      try {
        if (authMode.value === 'signin') {
          const { error } = await signIn(email.value, password.value)
          if (error) authError.value = error.message
          else await fetchAllData()
        } else {
          const { error } = await signUp(email.value, password.value)
          if (error) authError.value = error.message
          else { alert('Check your email to verify, then sign in.'); authMode.value = 'signin'; password.value = '' }
        }
      } catch (e) { authError.value = e.message }
      finally { authSubmitting.value = false }
    }

    const handleSignOut = async () => { await signOut() }
    const handleSnapshot = async () => { await createSnapshot(); alert('Snapshot saved! ✅') }
    
    const toggleValuesHidden = () => {
      valuesHidden.value = !valuesHidden.value
      localStorage.setItem('valuesHidden', valuesHidden.value.toString())
    }
    
    // Session timeout - track activity with localStorage persistence
    const updateActivity = () => { 
      const now = Date.now()
      lastActivity.value = now
      localStorage.setItem('lastActivity', now.toString())
    }
    
    // Initialize lastActivity from localStorage or now
    const storedActivity = localStorage.getItem('lastActivity')
    if (storedActivity) {
      lastActivity.value = parseInt(storedActivity)
    } else {
      updateActivity()
    }
    
    const checkSessionTimeout = async () => {
      if (!isAuthenticated.value) return
      
      const timeSinceActivity = Date.now() - lastActivity.value
      if (timeSinceActivity > SESSION_TIMEOUT) {
        localStorage.removeItem('lastActivity')
        await signOut()
        alert('Session expired due to inactivity. Please sign in again.')
      }
    }

    // Auto-fetch exchange rates (once per day)
    const autoFetchRates = async () => {
      const lastFetch = localStorage.getItem('lastRateFetch')
      const now = Date.now()
      const oneDay = 24 * 60 * 60 * 1000
      
      if (lastFetch && (now - parseInt(lastFetch)) < oneDay) return
      
      try {
        const response = await fetch('https://api.frankfurter.app/latest?from=EUR&to=INR,USD')
        const data = await response.json()
        
        if (data.rates && user.value) {
          const { supabase } = await import('./lib/supabase')
          await supabase.from('settings').update({
            eur_to_inr: data.rates.INR,
            eur_to_usd: data.rates.USD,
            usd_to_eur: 1 / data.rates.USD
          }).eq('user_id', user.value.id)
          
          localStorage.setItem('lastRateFetch', now.toString())
          await fetchAllData()
          console.log('Exchange rates auto-updated')
        }
      } catch (error) {
        console.error('Auto-fetch rates failed:', error)
      }
    }

    onMounted(async () => {
      await initialize()
      if (isAuthenticated.value) {
        await fetchAllData()
        await autoFetchRates()
      }
      
      // Session timeout: track activity
      const activityEvents = ['click', 'keydown', 'scroll', 'touchstart']
      activityEvents.forEach(event => {
        document.addEventListener(event, updateActivity, { passive: true })
      })
      
      // Check session timeout every 30 seconds
      setInterval(checkSessionTimeout, 30 * 1000)
      
      // Also check when tab becomes visible again
      document.addEventListener('visibilitychange', () => {
        if (document.visibilityState === 'visible') {
          checkSessionTimeout()
        }
      })
      
      // Reset activity on successful auth
      if (isAuthenticated.value) {
        updateActivity()
      }
    })

    return { authLoading, isAuthenticated, currentTab, displayCurrency, valuesHidden, tabs, currentComponent, authMode, email, password, authError, authSubmitting, dataLoading, handleAuth, handleSignOut, handleSnapshot, toggleValuesHidden }
  }
}
</script>

<style>
/* Loading */
.loading-screen, .loading-content {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  min-height: 100vh;
  gap: 1rem;
}

.loading-content {
  min-height: 50vh;
}

.loader {
  width: 40px;
  height: 40px;
  border: 3px solid var(--border);
  border-top-color: var(--primary);
  border-radius: 50%;
  animation: spin 0.8s linear infinite;
}

@keyframes spin { to { transform: rotate(360deg); } }

/* Auth Screen */
.auth-screen {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 2rem;
}

.auth-card {
  width: 100%;
  max-width: 420px;
  padding: 2.5rem;
}

.auth-header {
  text-align: center;
  margin-bottom: 2rem;
}

.logo {
  font-size: 3rem;
  display: block;
  margin-bottom: 1rem;
}

.auth-header h1 {
  font-size: 1.75rem;
  font-weight: 700;
  margin-bottom: 0.5rem;
}

.auth-header p {
  color: var(--text-secondary);
  font-size: 0.95rem;
}

.auth-tabs {
  display: flex;
  gap: 0.5rem;
  margin-bottom: 1.5rem;
  background: var(--bg-glass);
  padding: 4px;
  border-radius: 10px;
}

.auth-tabs button {
  flex: 1;
  padding: 0.75rem;
  border: none;
  background: transparent;
  color: var(--text-muted);
  font-weight: 600;
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.2s;
}

.auth-tabs button.active {
  background: var(--primary);
  color: white;
}

.auth-form {
  display: flex;
  flex-direction: column;
  gap: 1.25rem;
}

.input-group {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.input-group label {
  font-size: 0.85rem;
  font-weight: 500;
  color: var(--text-secondary);
}

.input-group input {
  padding: 0.875rem 1rem;
  background: var(--bg-glass);
  border: 1px solid var(--border);
  border-radius: 10px;
  color: var(--text);
  font-size: 1rem;
}

.input-group input:focus {
  border-color: var(--primary);
}

.error-msg {
  padding: 0.75rem;
  background: rgba(239, 68, 68, 0.1);
  border: 1px solid rgba(239, 68, 68, 0.3);
  border-radius: 8px;
  color: var(--danger);
  font-size: 0.9rem;
}

/* Buttons */
.btn-primary {
  padding: 0.875rem 1.5rem;
  background: linear-gradient(135deg, var(--primary), var(--primary-dark));
  color: white;
  border: none;
  border-radius: 10px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-primary:hover:not(:disabled) {
  transform: translateY(-1px);
  box-shadow: 0 4px 20px rgba(99, 102, 241, 0.4);
}

.btn-primary:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.btn-full { width: 100%; }

.btn-ghost {
  padding: 0.5rem 1rem;
  background: transparent;
  border: 1px solid var(--border);
  border-radius: 8px;
  color: var(--text-secondary);
  font-weight: 500;
  cursor: pointer;
  font-size: 0.85rem;
}

.btn-ghost:hover {
  border-color: var(--primary);
  color: var(--text);
}

.btn-icon {
  width: 40px;
  height: 40px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: var(--bg-glass);
  border: 1px solid var(--border);
  border-radius: 10px;
  cursor: pointer;
  font-size: 1.1rem;
}

.btn-icon:hover {
  background: var(--primary);
}

/* App Container */
.app-container {
  max-width: 1400px;
  margin: 0 auto;
  padding: 1rem;
}

/* Header */
.app-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1rem 1.5rem;
  margin-bottom: 1.5rem;
}

.header-left {
  display: flex;
  align-items: center;
  gap: 0.75rem;
}

.logo-small {
  font-size: 1.5rem;
}

.header-left h1 {
  font-size: 1.25rem;
  font-weight: 700;
}

.header-right {
  display: flex;
  align-items: center;
  gap: 0.75rem;
}

.currency-switch {
  display: flex;
  background: var(--bg-glass);
  border-radius: 8px;
  padding: 3px;
}

.currency-switch button {
  padding: 0.5rem 1rem;
  border: none;
  background: transparent;
  color: var(--text-muted);
  font-weight: 600;
  border-radius: 6px;
  cursor: pointer;
}

.currency-switch button.active {
  background: var(--primary);
  color: white;
}

/* Navigation */
.app-nav {
  display: flex;
  gap: 0.5rem;
  margin-bottom: 1.5rem;
  overflow-x: auto;
  padding-bottom: 0.5rem;
}

.app-nav button {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.75rem 1.25rem;
  background: var(--bg-card);
  border: 1px solid var(--border);
  border-radius: 10px;
  color: var(--text-secondary);
  font-weight: 500;
  cursor: pointer;
  white-space: nowrap;
  transition: all 0.2s;
}

.app-nav button:hover {
  border-color: var(--primary);
}

.app-nav button.active {
  background: linear-gradient(135deg, var(--primary), var(--primary-dark));
  border-color: transparent;
  color: white;
}

.nav-icon {
  font-size: 1.1rem;
}

/* Main Content */
.app-main {
  animation: fadeIn 0.3s ease;
}

@keyframes fadeIn {
  from { opacity: 0; transform: translateY(8px); }
  to { opacity: 1; transform: translateY(0); }
}

/* ========================================
   Page Banner - Consistent across all tabs
   ======================================== */
.page-banner {
  background: var(--bg-card);
  backdrop-filter: blur(10px);
  border: 1px solid var(--border);
  border-radius: 16px;
  padding: 2rem;
  text-align: center;
  margin-bottom: 1.5rem;
}

.page-banner.accent-primary {
  border-color: rgba(99, 102, 241, 0.3);
  background: linear-gradient(135deg, rgba(99, 102, 241, 0.1), rgba(16, 185, 129, 0.05));
}

.page-banner.accent-success {
  border-color: rgba(16, 185, 129, 0.3);
  background: linear-gradient(135deg, rgba(16, 185, 129, 0.1), transparent);
}

.page-banner.accent-danger {
  border-color: rgba(239, 68, 68, 0.3);
  background: linear-gradient(135deg, rgba(239, 68, 68, 0.1), transparent);
}

.page-banner.accent-warning {
  border-color: rgba(245, 158, 11, 0.3);
  background: linear-gradient(135deg, rgba(245, 158, 11, 0.1), transparent);
}

.page-banner .banner-label {
  font-size: 0.85rem;
  color: var(--text-secondary);
  margin-bottom: 0.5rem;
  text-transform: uppercase;
  letter-spacing: 0.08em;
  font-weight: 500;
}

.page-banner .banner-value {
  font-size: 2.5rem;
  font-weight: 700;
  color: var(--text);
  line-height: 1.2;
}

.page-banner .banner-value.gradient {
  background: linear-gradient(135deg, #10b981, #6366f1);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
}

.page-banner .banner-value.primary { color: var(--primary); }
.page-banner .banner-value.success { color: var(--success); }
.page-banner .banner-value.danger { color: var(--danger); }

.page-banner .banner-secondary {
  font-size: 1.1rem;
  color: var(--text-muted);
  margin-top: 0.5rem;
}

.page-banner .banner-subtitle {
  font-size: 0.9rem;
  color: var(--text-secondary);
  margin-top: 0.25rem;
}

/* Multi-column banner (like CashFlow summary) */
.page-banner-row {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(140px, 1fr));
  gap: 1rem;
  margin-bottom: 1.5rem;
}

.page-banner-row .page-banner {
  margin-bottom: 0;
  padding: 1.5rem 1rem;
}

.page-banner-row .banner-value {
  font-size: 1.75rem;
}

/* Mobile adjustments */
@media (max-width: 768px) {
  .page-banner {
    padding: 1.5rem;
  }
  
  .page-banner .banner-value {
    font-size: 2rem;
  }
  
  .page-banner-row .banner-value {
    font-size: 1.5rem;
  }
}

/* Mobile */
@media (max-width: 768px) {
  .app-header {
    flex-wrap: wrap;
    gap: 1rem;
  }
  
  .header-left h1 {
    display: none;
  }
  
  .nav-label {
    display: none;
  }
  
  .app-nav button {
    padding: 0.75rem;
  }
}
</style>
