import { ref, computed } from 'vue'
import { supabase } from '../lib/supabase'

const user = ref(null)
const session = ref(null)
const loading = ref(true)

export function useAuth() {
  const isAuthenticated = computed(() => !!user.value)

  // Initialize auth state
  const initialize = async () => {
    try {
      const { data: { session: currentSession } } = await supabase.auth.getSession()
      session.value = currentSession
      user.value = currentSession?.user ?? null
    } catch (error) {
      console.error('Error initializing auth:', error)
    } finally {
      loading.value = false
    }

    // Listen for auth changes
    supabase.auth.onAuthStateChange((_event, newSession) => {
      session.value = newSession
      user.value = newSession?.user ?? null
    })
  }

  // Sign up
  const signUp = async (email, password) => {
    try {
      const { data, error } = await supabase.auth.signUp({
        email,
        password
      })
      
      if (error) throw error
      
      // Create default settings and data for new user
      if (data.user) {
        await initializeUserData(data.user.id)
      }
      
      return { data, error: null }
    } catch (error) {
      return { data: null, error }
    }
  }

  // Sign in
  const signIn = async (email, password) => {
    try {
      const { data, error } = await supabase.auth.signInWithPassword({
        email,
        password
      })
      
      if (error) throw error
      return { data, error: null }
    } catch (error) {
      return { data: null, error }
    }
  }

  // Sign out
  const signOut = async () => {
    try {
      const { error } = await supabase.auth.signOut()
      if (error) throw error
      user.value = null
      session.value = null
      return { error: null }
    } catch (error) {
      return { error }
    }
  }

  // Initialize default data for new user
  const initializeUserData = async (userId) => {
    try {
      // Insert default settings
      await supabase.from('settings').insert({
        user_id: userId,
        eur_to_inr: 107.58,
        eur_to_usd: 1.04,
        usd_to_eur: 0.96,
        target_crypto_exposure: 35,
        target_illiquid_assets: 40,
        target_debt_to_networth: 30,
        target_emergency_buffer: 15000,
        base_income: 5312,
        kindergeld: 0,
        upasana_govt: 0,
        current_phase: 1
      })

      // Insert default expenses
      await supabase.from('expenses').insert({
        user_id: userId,
        rent: 1276.76,
        parking: 55,
        phone: 15,
        internet: 65,
        electricity: 76,
        groceries: 400,
        upasana: 250,
        car_loan_min: 430,
        personal_loan_min: 509,
        car_insurance_monthly: 72.33,
        legal_insurance_monthly: 29.17,
        lohi_monthly: 22.75,
        eating_out: 250
      })

      // Insert default Indian allocations
      await supabase.from('indian_allocations').insert({
        user_id: userId,
        ppfas_sourabh: 11000,
        ppfas_dhea: 1500,
        rd1: 10000,
        rd2: 5000
      })

      // Insert default investments (India)
      const indiaInvestments = [
        { category: 'india', name: 'Zerodha Demat', amount: 1021000, currency: 'INR', is_illiquid: false },
        { category: 'india', name: 'HDFC Demat (Sourabh)', amount: 333000, currency: 'INR', is_illiquid: false },
        { category: 'india', name: 'HDFC Demat (Upasana)', amount: 25000, currency: 'INR', is_illiquid: false },
        { category: 'india', name: 'PPFAS Flexi Cap (Sourabh)', amount: 1356000, currency: 'INR', is_illiquid: false },
        { category: 'india', name: 'PPFAS Flexi Cap (Dhea)', amount: 36500, currency: 'INR', is_illiquid: false },
        { category: 'india', name: 'Fixed Deposits', amount: 100000, currency: 'INR', is_illiquid: false },
        { category: 'india', name: 'Recurring Deposit 1', amount: 178000, currency: 'INR', is_illiquid: false },
        { category: 'india', name: 'Recurring Deposit 2', amount: 75000, currency: 'INR', is_illiquid: false },
        { category: 'india', name: 'HDFC Life ULIP', amount: 379000, currency: 'INR', is_illiquid: false },
        { category: 'india', name: 'Property', amount: 5000000, currency: 'INR', is_illiquid: true }
      ]

      for (const inv of indiaInvestments) {
        await supabase.from('investments').insert({ user_id: userId, ...inv })
      }

      // Insert Germany investments
      await supabase.from('investments').insert({
        user_id: userId,
        category: 'germany',
        name: 'VAY ESOPs',
        amount: 100000,
        currency: 'EUR',
        is_illiquid: true
      })

      // Insert crypto investments
      const cryptoInvestments = [
        { category: 'crypto', name: 'Liquid Assets', amount: 15000, currency: 'USD', is_locked: false },
        { category: 'crypto', name: 'MegaETH', amount: 39000, currency: 'USD', is_locked: true, invested_amount: 14000 },
        { category: 'crypto', name: 'Initia (INIT)', amount: 200, currency: 'USD', is_locked: true, invested_amount: 650 },
        { category: 'crypto', name: 'One Balance', amount: 973, currency: 'USD', is_locked: true, invested_amount: 500 },
        { category: 'crypto', name: 'Monerium', amount: 1000, currency: 'USD', is_locked: true, invested_amount: 1000 }
      ]

      for (const crypto of cryptoInvestments) {
        await supabase.from('investments').insert({ user_id: userId, ...crypto })
      }

      // Insert savings
      await supabase.from('savings').insert([
        { user_id: userId, name: 'HDFC (Kamal)', amount: 80000, currency: 'INR' },
        { user_id: userId, name: 'Sourabh EUR', amount: 800, currency: 'EUR' }
      ])

      // Insert liabilities
      await supabase.from('liabilities').insert([
        { user_id: userId, name: 'Personal Loan', amount: 36000, currency: 'EUR', apr: 4.7, min_payment: 509 },
        { user_id: userId, name: 'Car Loan', amount: 41400, currency: 'EUR', apr: 0, min_payment: 430 },
        { user_id: userId, name: 'Credit Card', amount: 2100, currency: 'EUR', apr: 18, min_payment: 0 }
      ])

      // Insert phase progress
      await supabase.from('phase_progress').insert([
        { user_id: userId, phase: 1, name: 'Clear Credit Card', target: 2100, current: 420, is_complete: false },
        { user_id: userId, phase: 2, name: 'Build €15k Buffer', target: 15000, current: 1500, is_complete: false }
      ])

      // Insert investment rules
      const rules = [
        { text: 'No Fresh Crypto', color: '#ef4444', order_index: 1 },
        { text: 'Wait for Crash: BTC $50k • ETH $1.5k • HYPE $20', color: '#f59e0b', order_index: 2 },
        { text: 'Fresh Capital → Buffer + PPFAS + COPX only', color: '#10b981', order_index: 3 },
        { text: 'MegaETH TGE: Recover $13,885 first', color: '#3b82f6', order_index: 4 }
      ]

      for (const rule of rules) {
        await supabase.from('investment_rules').insert({ user_id: userId, ...rule })
      }

      console.log('User data initialized successfully')
    } catch (error) {
      console.error('Error initializing user data:', error)
    }
  }

  return {
    user,
    session,
    loading,
    isAuthenticated,
    initialize,
    signUp,
    signIn,
    signOut
  }
}
