import { ref, computed } from 'vue'
import { supabase } from '../lib/supabase'
import { useAuth } from './useAuth'

const settings = ref(null)
const investments = ref([])
const savings = ref([])
const liabilities = ref([])
const phaseProgress = ref([])
const investmentRules = ref([])
const snapshots = ref([])
const incomeSources = ref([])
const expenseItems = ref([])
const indianAllocations = ref(null)
const loading = ref(false)

export function useFinanceData() {
  const { user } = useAuth()

  const fetchAllData = async () => {
    if (!user.value) return
    loading.value = true
    
    try {
      const userId = user.value.id

      const [
        settingsRes,
        investmentsRes,
        savingsRes,
        liabilitiesRes,
        phaseRes,
        rulesRes,
        snapshotsRes,
        incomeRes,
        expenseRes,
        indianRes
      ] = await Promise.all([
        supabase.from('settings').select('*').eq('user_id', userId).single(),
        supabase.from('investments').select('*').eq('user_id', userId).order('created_at'),
        supabase.from('savings').select('*').eq('user_id', userId).order('created_at'),
        supabase.from('liabilities').select('*').eq('user_id', userId).order('created_at'),
        supabase.from('phase_progress').select('*').eq('user_id', userId).order('phase'),
        supabase.from('investment_rules').select('*').eq('user_id', userId).order('order_index'),
        supabase.from('snapshots').select('*').eq('user_id', userId).gte('snapshot_date', new Date(Date.now() - 90 * 24 * 60 * 60 * 1000).toISOString()).order('snapshot_date'),
        supabase.from('income_sources').select('*').eq('user_id', userId).order('created_at'),
        supabase.from('expense_items').select('*').eq('user_id', userId).order('category').order('created_at'),
        supabase.from('indian_allocations').select('*').eq('user_id', userId).single()
      ])

      settings.value = settingsRes.data
      investments.value = investmentsRes.data || []
      savings.value = savingsRes.data || []
      liabilities.value = liabilitiesRes.data || []
      phaseProgress.value = phaseRes.data || []
      investmentRules.value = rulesRes.data || []
      snapshots.value = snapshotsRes.data || []
      incomeSources.value = incomeRes.data || []
      expenseItems.value = expenseRes.data || []
      indianAllocations.value = indianRes.data
    } catch (error) {
      console.error('Error fetching data:', error)
    } finally {
      loading.value = false
    }
  }

  const convertToEUR = (amount, currency) => {
    if (!settings.value) return amount
    if (currency === 'EUR') return amount
    if (currency === 'INR') return amount / (settings.value.eur_to_inr || 107.58)
    if (currency === 'USD') return amount * (settings.value.usd_to_eur || 0.96)
    return amount
  }

  const convertToINR = (amount, currency) => {
    if (!settings.value) return amount
    const rate = settings.value.eur_to_inr || 107.58
    if (currency === 'INR') return amount
    if (currency === 'EUR') return amount * rate
    if (currency === 'USD') return amount * (settings.value.usd_to_eur || 0.96) * rate
    return amount
  }

  const formatCurrency = (amount, currency) => {
    if (currency === 'INR') return `₹${amount.toLocaleString('en-IN', { maximumFractionDigits: 0 })}`
    if (currency === 'EUR') return `€${amount.toLocaleString('en-DE', { maximumFractionDigits: 0 })}`
    if (currency === 'USD') return `$${amount.toLocaleString('en-US', { maximumFractionDigits: 0 })}`
    return amount.toString()
  }

  const getTotalInvestments = computed(() => {
    let total = 0
    investments.value.forEach(inv => { total += convertToEUR(inv.amount, inv.currency) })
    savings.value.forEach(sav => { total += convertToEUR(sav.amount, sav.currency) })
    return total
  })

  const getTotalLiabilities = computed(() => {
    return liabilities.value.reduce((sum, l) => sum + convertToEUR(l.amount, l.currency), 0)
  })

  const getNetWorth = computed(() => getTotalInvestments.value - getTotalLiabilities.value)

  const getCryptoTotal = computed(() => {
    return investments.value.filter(i => i.category === 'crypto').reduce((sum, i) => sum + convertToEUR(i.amount, i.currency), 0)
  })

  const getIlliquidTotal = computed(() => {
    return investments.value.filter(i => i.is_illiquid).reduce((sum, i) => sum + convertToEUR(i.amount, i.currency), 0)
  })

  const getCryptoExposure = computed(() => {
    // Crypto as % of total investments (not net worth)
    return getTotalInvestments.value > 0 ? (getCryptoTotal.value / getTotalInvestments.value) * 100 : 0
  })

  const getIlliquidExposure = computed(() => {
    // Illiquid as % of total investments (not net worth)
    return getTotalInvestments.value > 0 ? (getIlliquidTotal.value / getTotalInvestments.value) * 100 : 0
  })

  const getDebtToNetWorth = computed(() => {
    return getNetWorth.value > 0 ? (getTotalLiabilities.value / getNetWorth.value) * 100 : 0
  })

  // Income & Expense calculations
  const getTotalMonthlyIncome = computed(() => {
    return incomeSources.value.reduce((sum, inc) => sum + convertToEUR(inc.amount, inc.currency || 'EUR'), 0)
  })

  const getTotalMonthlyExpenses = computed(() => {
    // Only count monthly expenses - yearly/quarterly are shown separately for FYI
    return expenseItems.value
      .filter(exp => exp.frequency === 'monthly')
      .reduce((sum, exp) => sum + convertToEUR(exp.amount, exp.currency || 'EUR'), 0)
  })

  const getMonthlySurplus = computed(() => {
    return getTotalMonthlyIncome.value - getTotalMonthlyExpenses.value
  })

  // Savings rate as % of income
  const getSavingsRate = computed(() => {
    if (getTotalMonthlyIncome.value <= 0) return 0
    return (getMonthlySurplus.value / getTotalMonthlyIncome.value) * 100
  })

  const createSnapshot = async () => {
    if (!user.value) return
    try {
      await supabase.from('snapshots').insert({
        user_id: user.value.id,
        snapshot_date: new Date().toISOString().split('T')[0],
        net_worth: getNetWorth.value,
        total_investments: getTotalInvestments.value,
        total_liabilities: getTotalLiabilities.value,
        crypto_total: getCryptoTotal.value,
        illiquid_total: getIlliquidTotal.value,
        crypto_exposure_pct: getCryptoExposure.value,
        illiquid_exposure_pct: getIlliquidExposure.value,
        debt_to_networth_pct: getDebtToNetWorth.value
      })
      await fetchAllData()
    } catch (error) {
      console.error('Error creating snapshot:', error)
    }
  }

  return {
    settings, investments, savings, liabilities, phaseProgress, investmentRules, snapshots, incomeSources, expenseItems, indianAllocations, loading,
    fetchAllData, convertToEUR, convertToINR, formatCurrency, createSnapshot,
    getTotalInvestments, getTotalLiabilities, getNetWorth, getCryptoTotal, getIlliquidTotal,
    getCryptoExposure, getIlliquidExposure, getDebtToNetWorth,
    getTotalMonthlyIncome, getTotalMonthlyExpenses, getMonthlySurplus, getSavingsRate
  }
}
