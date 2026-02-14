<template>
  <div class="dashboard">
    <!-- Net Worth Hero -->
    <div class="page-banner accent-primary">
      <div class="banner-label">Net Worth</div>
      <div class="banner-value gradient">{{ formatDisplay(netWorth, displayCurrency) }}</div>
      <div class="banner-secondary">{{ formatDisplay(netWorth, displayCurrency === 'EUR' ? 'INR' : 'EUR') }}</div>
    </div>

    <!-- Metrics Grid -->
    <div class="metrics-grid">
      <div class="metric-card glass-card">
        <div class="metric-icon">🪙</div>
        <div class="metric-content">
          <div class="metric-label">Crypto Exposure</div>
          <div class="metric-value">{{ cryptoExposure.toFixed(1) }}%</div>
          <div class="metric-bar">
            <div class="bar-fill" :style="{ width: `${Math.min(cryptoExposure, 100)}%`, background: getBarColor(cryptoExposure, targetCrypto) }"></div>
          </div>
          <div class="metric-target" :style="{ color: getBarColor(cryptoExposure, targetCrypto) }">Target: {{ targetCrypto }}%</div>
        </div>
      </div>

      <div class="metric-card glass-card">
        <div class="metric-icon">🏠</div>
        <div class="metric-content">
          <div class="metric-label">Illiquid Assets</div>
          <div class="metric-value">{{ illiquidExposure.toFixed(1) }}%</div>
          <div class="metric-bar">
            <div class="bar-fill" :style="{ width: `${Math.min(illiquidExposure, 100)}%`, background: getBarColor(illiquidExposure, targetIlliquid) }"></div>
          </div>
          <div class="metric-target" :style="{ color: getBarColor(illiquidExposure, targetIlliquid) }">Target: {{ targetIlliquid }}%</div>
        </div>
      </div>

      <div class="metric-card glass-card">
        <div class="metric-icon">📊</div>
        <div class="metric-content">
          <div class="metric-label">Debt Ratio</div>
          <div class="metric-value">{{ debtToNetWorth.toFixed(1) }}%</div>
          <div class="metric-bar">
            <div class="bar-fill" :style="{ width: `${Math.min(debtToNetWorth, 100)}%`, background: getBarColorInverse(debtToNetWorth, targetDebt) }"></div>
          </div>
          <div class="metric-target" :style="{ color: getBarColorInverse(debtToNetWorth, targetDebt) }">Target: &lt;{{ targetDebt }}%</div>
        </div>
      </div>

      <div class="metric-card glass-card surplus-card">
        <div class="metric-icon">💵</div>
        <div class="metric-content">
          <div class="metric-label">Monthly Surplus</div>
          <div class="metric-value">€{{ maskNumber(monthlySurplus) }}</div>
          <div class="metric-bar">
            <div class="bar-fill savings-bar" :style="{ width: `${Math.min(savingsRate, 100)}%` }"></div>
          </div>
          <div class="metric-target savings-rate">Savings Rate: {{ savingsRate.toFixed(0) }}%</div>
        </div>
      </div>
    </div>

    <!-- Investment Rules -->
    <div class="rules-section glass-card" v-if="rules.length">
      <h3>📜 Investment Rules</h3>
      <div class="rules-grid">
        <div v-for="rule in rules" :key="rule.id" class="rule-item" :style="{ borderColor: rule.color }">
          {{ rule.text }}
        </div>
      </div>
    </div>

    <!-- Phase Progress -->
    <div class="phase-section glass-card" v-if="activePhases.length">
      <h3>🎯 Goal Progress</h3>
      <div class="phases-list">
        <div v-for="phase in activePhases" :key="phase.id" class="phase-item">
          <div class="phase-header">
            <span class="phase-name">Phase {{ phase.phase }}: {{ phase.name }}</span>
            <span class="phase-amount">€{{ maskNumber(phase.current || 0) }} / €{{ maskNumber(phase.target || 0) }}</span>
          </div>
          <div class="phase-bar">
            <div class="phase-fill" :style="{ width: `${Math.min(((phase.current || 0) / (phase.target || 1)) * 100, 100)}%` }"></div>
          </div>
          <div class="phase-percent">{{ (((phase.current || 0) / (phase.target || 1)) * 100).toFixed(0) }}% complete</div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { computed } from 'vue'
import { useFinanceData } from '../composables/useFinanceData'

export default {
  name: 'Dashboard',
  props: { 
    displayCurrency: { type: String, default: 'EUR' },
    valuesHidden: { type: Boolean, default: false }
  },
  setup(props) {
    // Use centralized calculations from useFinanceData (single source of truth)
    const { 
      settings, phaseProgress, investmentRules, 
      convertToINR, formatCurrency,
      getNetWorth, getCryptoExposure, getIlliquidExposure, getDebtToNetWorth,
      getMonthlySurplus, getSavingsRate 
    } = useFinanceData()

    const rules = computed(() => investmentRules.value || [])
    
    // Use values from useFinanceData directly (no duplicate calculations)
    const netWorth = computed(() => getNetWorth.value)
    const cryptoExposure = computed(() => getCryptoExposure.value)
    const illiquidExposure = computed(() => getIlliquidExposure.value)
    const debtToNetWorth = computed(() => getDebtToNetWorth.value)
    const monthlySurplus = computed(() => Math.round(getMonthlySurplus.value))
    const savingsRate = computed(() => getSavingsRate.value)

    const targetCrypto = computed(() => settings.value?.target_crypto_exposure || 35)
    const targetIlliquid = computed(() => settings.value?.target_illiquid_assets || 40)
    const targetDebt = computed(() => settings.value?.target_debt_to_networth || 30)
    const activePhases = computed(() => phaseProgress.value?.filter(p => !p.is_complete) || [])

    const formatDisplay = (amount, currency) => {
      if (props.valuesHidden) return '••••••'
      return currency === 'EUR' ? formatCurrency(amount, 'EUR') : formatCurrency(convertToINR(amount, 'EUR'), 'INR')
    }
    const maskNumber = (num) => props.valuesHidden ? '••••' : num.toLocaleString()
    const getBarColor = (current, target) => Math.abs(current - target) <= 5 ? '#10b981' : Math.abs(current - target) <= 10 ? '#f59e0b' : '#ef4444'
    const getBarColorInverse = (current, target) => current <= target ? '#10b981' : current <= target + 5 ? '#f59e0b' : '#ef4444'

    return { rules, netWorth, cryptoExposure, illiquidExposure, debtToNetWorth, monthlySurplus, savingsRate, targetCrypto, targetIlliquid, targetDebt, activePhases, formatDisplay, maskNumber, getBarColor, getBarColorInverse }
  }
}
</script>

<style scoped>
.dashboard {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}

/* Hero card now uses global .page-banner styles */

.metrics-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
  gap: 1rem;
}

.metric-card {
  padding: 1.5rem;
  display: flex;
  gap: 1rem;
}

.metric-icon {
  font-size: 2rem;
}

.metric-content {
  flex: 1;
}

.metric-label {
  font-size: 0.85rem;
  color: var(--text-secondary);
  margin-bottom: 0.25rem;
}

.metric-value {
  font-size: 1.75rem;
  font-weight: 700;
  margin-bottom: 0.5rem;
}

.metric-bar {
  height: 4px;
  background: var(--border);
  border-radius: 2px;
  overflow: hidden;
  margin-bottom: 0.5rem;
}

.bar-fill {
  height: 100%;
  border-radius: 2px;
  transition: width 0.3s ease;
}

.metric-target {
  font-size: 0.8rem;
  font-weight: 500;
}

.metric-note {
  font-size: 0.8rem;
  color: var(--text-muted);
}

.surplus-card {
  border-color: rgba(16, 185, 129, 0.2);
  background: linear-gradient(135deg, rgba(16, 185, 129, 0.1), transparent);
}

.savings-bar {
  background: linear-gradient(90deg, #10b981, #6366f1) !important;
}

.savings-rate {
  color: var(--success) !important;
}

.rules-section, .phase-section {
  padding: 1.5rem;
}

.rules-section h3, .phase-section h3 {
  font-size: 1.1rem;
  margin-bottom: 1rem;
  color: var(--text-secondary);
}

.rules-grid {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.rule-item {
  padding: 0.75rem 1rem;
  background: var(--bg-glass);
  border-left: 3px solid;
  border-radius: 6px;
  font-size: 0.9rem;
}

.phases-list {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.phase-item {
  padding: 1rem;
  background: var(--bg-glass);
  border-radius: 10px;
}

.phase-header {
  display: flex;
  justify-content: space-between;
  margin-bottom: 0.75rem;
}

.phase-name {
  font-weight: 600;
}

.phase-amount {
  color: var(--primary);
  font-weight: 600;
}

.phase-bar {
  height: 8px;
  background: var(--border);
  border-radius: 4px;
  overflow: hidden;
  margin-bottom: 0.5rem;
}

.phase-fill {
  height: 100%;
  background: linear-gradient(90deg, var(--primary), var(--primary-light));
  border-radius: 4px;
  transition: width 0.3s ease;
}

.phase-percent {
  font-size: 0.8rem;
  color: var(--text-muted);
}

@media (max-width: 768px) {
  .hero-value { font-size: 2.25rem; }
  
  .metrics-grid { 
    grid-template-columns: 1fr 1fr; 
    gap: 0.75rem;
  }
  
  .metric-card {
    padding: 1rem;
    flex-direction: column;
    align-items: center;
    text-align: center;
    min-height: 160px;
  }
  
  .metric-icon {
    font-size: 1.75rem;
    margin-bottom: 0.25rem;
  }
  
  .metric-content {
    display: flex;
    flex-direction: column;
    align-items: center;
  }
  
  .metric-label {
    font-size: 0.75rem;
    white-space: nowrap;
  }
  
  .metric-value {
    font-size: 1.5rem;
  }
  
  .metric-bar {
    width: 100%;
  }
  
  .metric-target, .metric-note {
    font-size: 0.7rem;
  }
}
</style>
