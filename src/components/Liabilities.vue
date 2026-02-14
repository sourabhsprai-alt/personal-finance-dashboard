<template>
  <div class="liabilities">
    <div class="page-banner accent-danger">
      <div class="banner-label">Total Liabilities</div>
      <div class="banner-value danger">€{{ maskNumber(totalLiabilities) }}</div>
      <div class="banner-subtitle">Debt-to-Net-Worth: {{ debtToNetWorth.toFixed(1) }}%</div>
    </div>

    <div class="liabilities-grid">
      <div v-for="liab in liabilitiesList" :key="liab.id" class="liability-card">
        <div class="card-header">
          <h3>{{ liab.name }}</h3>
          <button @click="deleteLiability(liab.id)" class="btn-delete">🗑️</button>
        </div>
        
        <div class="liability-info">
          <div class="info-row">
            <span class="label">Balance:</span>
            <div class="value-edit">
              <input 
                type="number" 
                :value="liab.amount"
                @change="handleUpdate(liab.id, 'amount', $event.target.value)"
                class="editable-value"
              />
              <span class="currency">EUR</span>
            </div>
          </div>
          
          <div class="info-row">
            <span class="label">APR:</span>
            <div class="value-edit">
              <input 
                type="number" 
                step="0.1"
                :value="liab.apr"
                @change="handleUpdate(liab.id, 'apr', $event.target.value)"
                class="editable-value small"
              />
              <span class="currency">%</span>
            </div>
          </div>
          
          <div class="info-row">
            <span class="label">Min Payment:</span>
            <div class="value-edit">
              <input 
                type="number" 
                :value="liab.min_payment"
                @change="handleUpdate(liab.id, 'min_payment', $event.target.value)"
                class="editable-value"
              />
              <span class="currency">EUR/mo</span>
            </div>
          </div>
        </div>

        <div class="payoff-info">
          <div class="payoff-row">
            <span>Monthly Interest:</span>
            <span class="interest-cost">€{{ valuesHidden ? '••••' : calculateMonthlyInterest(liab).toFixed(0) }}</span>
          </div>
          <div class="payoff-row">
            <span>Payoff (min payment):</span>
            <span>{{ calculatePayoffMonths(liab, liab.min_payment) }} months</span>
          </div>
          <div class="payoff-row highlight" v-if="monthlySurplus > 0">
            <span>Payoff (+ €{{ maskNumber(monthlySurplus) }} surplus):</span>
            <span class="fast-payoff">{{ calculatePayoffMonths(liab, liab.min_payment + monthlySurplus) }} months</span>
          </div>
          <div class="payoff-row savings" v-if="monthlySurplus > 0">
            <span>Interest saved:</span>
            <span class="interest-saved">€{{ maskNumber(calculateInterestSaved(liab)) }}</span>
          </div>
        </div>
      </div>

      <!-- Add New Liability -->
      <div class="liability-card add-card" v-if="showAddLiability">
        <h3>Add New Liability</h3>
        <div class="add-form">
          <input v-model="newLiability.name" placeholder="Name (e.g., Personal Loan)" class="input-full" />
          <div class="form-row">
            <input v-model.number="newLiability.amount" type="number" placeholder="Balance (EUR)" />
            <input v-model.number="newLiability.apr" type="number" step="0.1" placeholder="APR %" />
            <input v-model.number="newLiability.min_payment" type="number" placeholder="Min Payment" />
          </div>
          <div class="form-actions">
            <button @click="addLiability" class="btn-add-confirm">Add Liability</button>
            <button @click="showAddLiability = false" class="btn-cancel">Cancel</button>
          </div>
        </div>
      </div>
      
      <div v-else class="add-card-button" @click="showAddLiability = true">
        <span>+ Add Liability</span>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, computed } from 'vue'
import { useFinanceData } from '../composables/useFinanceData'
import { useAuth } from '../composables/useAuth'
import { supabase } from '../lib/supabase'

export default {
  name: 'Liabilities',
  props: {
    valuesHidden: { type: Boolean, default: false }
  },
  setup(props) {
    const { user } = useAuth()
    const {
      liabilities,
      fetchAllData,
      getMonthlySurplus,
      getTotalLiabilities,
      getDebtToNetWorth
    } = useFinanceData()

    const monthlySurplus = computed(() => Math.round(getMonthlySurplus.value))
    const maskNumber = (num) => props.valuesHidden ? '••••' : (typeof num === 'number' ? num.toLocaleString() : num)

    const showAddLiability = ref(false)
    const newLiability = ref({ name: '', amount: 0, apr: 0, min_payment: 0 })

    const liabilitiesList = computed(() => liabilities.value || [])

    // Use centralized calculations
    const totalLiabilities = computed(() => Math.round(getTotalLiabilities.value))
    const debtToNetWorth = computed(() => getDebtToNetWorth.value)

    const calculateMonthlyInterest = (liab) => {
      return (liab.amount * (liab.apr / 100)) / 12
    }

    // Calculate months to pay off debt
    const calculatePayoffMonths = (liab, monthlyPayment) => {
      if (monthlyPayment <= 0) return '∞'
      const monthlyRate = (liab.apr / 100) / 12
      if (monthlyRate === 0) return Math.ceil(liab.amount / monthlyPayment)
      
      const monthlyInterest = liab.amount * monthlyRate
      if (monthlyPayment <= monthlyInterest) return '∞'
      
      // Formula: n = -log(1 - (r * P / M)) / log(1 + r)
      const months = Math.ceil(
        -Math.log(1 - (monthlyRate * liab.amount / monthlyPayment)) / Math.log(1 + monthlyRate)
      )
      return isNaN(months) || months < 0 ? '∞' : months
    }

    // Calculate interest saved by paying surplus
    const calculateInterestSaved = (liab) => {
      const minPayment = liab.min_payment
      const withSurplus = minPayment + monthlySurplus.value
      
      const monthsMin = calculatePayoffMonths(liab, minPayment)
      const monthsFast = calculatePayoffMonths(liab, withSurplus)
      
      if (monthsMin === '∞' || monthsFast === '∞') return 0
      
      const totalPaidMin = monthsMin * minPayment
      const totalPaidFast = monthsFast * withSurplus
      
      // Interest = Total paid - Principal
      const interestMin = totalPaidMin - liab.amount
      const interestFast = totalPaidFast - liab.amount
      
      return Math.max(0, Math.round(interestMin - interestFast))
    }

    const handleUpdate = async (id, field, value) => {
      try {
        await supabase
          .from('liabilities')
          .update({ [field]: parseFloat(value) })
          .eq('id', id)
        await fetchAllData()
      } catch (error) {
        console.error('Error updating liability:', error)
      }
    }

    const deleteLiability = async (id) => {
      if (!confirm('Delete this liability?')) return
      try {
        await supabase.from('liabilities').delete().eq('id', id)
        await fetchAllData()
      } catch (error) {
        console.error('Error deleting liability:', error)
      }
    }

    const addLiability = async () => {
      if (!user.value || !newLiability.value.name) return
      try {
        await supabase.from('liabilities').insert({
          user_id: user.value.id,
          name: newLiability.value.name,
          amount: newLiability.value.amount,
          currency: 'EUR',
          apr: newLiability.value.apr,
          min_payment: newLiability.value.min_payment
        })
        newLiability.value = { name: '', amount: 0, apr: 0, min_payment: 0 }
        showAddLiability.value = false
        await fetchAllData()
      } catch (error) {
        console.error('Error adding liability:', error)
      }
    }

    return {
      liabilitiesList,
      totalLiabilities,
      debtToNetWorth,
      monthlySurplus,
      maskNumber,
      valuesHidden: props.valuesHidden,
      calculateMonthlyInterest,
      calculatePayoffMonths,
      calculateInterestSaved,
      handleUpdate,
      deleteLiability,
      showAddLiability,
      newLiability,
      addLiability
    }
  }
}
</script>

<style scoped>
.liabilities {
  display: flex;
  flex-direction: column;
  gap: 2rem;
}

/* Summary card now uses global .page-banner styles */

.liabilities-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 1.5rem;
}

.liability-card {
  background: var(--bg-light);
  border-radius: 1rem;
  padding: 1.5rem;
  border: 2px solid var(--border);
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1.5rem;
}

.card-header h3 {
  font-size: 1.3rem;
  color: var(--danger);
}

.btn-delete {
  padding: 0.25rem 0.5rem;
  background: transparent;
  border: none;
  cursor: pointer;
  opacity: 0.5;
  transition: opacity 0.2s;
}

.btn-delete:hover {
  opacity: 1;
}

.liability-info {
  display: flex;
  flex-direction: column;
  gap: 1rem;
  margin-bottom: 1.5rem;
}

.info-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.label {
  color: var(--text-muted);
  font-weight: 600;
}

.value-edit {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.editable-value {
  width: 100px;
  padding: 0.5rem;
  background: var(--bg);
  border: 1px solid var(--border);
  border-radius: 0.25rem;
  color: var(--text);
  font-size: 1rem;
  font-weight: 600;
  text-align: right;
}

.editable-value.small {
  width: 60px;
}

.editable-value:focus {
  outline: none;
  border-color: var(--primary);
}

.currency {
  font-weight: 600;
  color: var(--text-muted);
  font-size: 0.9rem;
}

.payoff-info {
  padding-top: 1rem;
  border-top: 1px solid var(--border);
}

.payoff-row {
  display: flex;
  justify-content: space-between;
  margin-bottom: 0.5rem;
  font-size: 0.9rem;
  color: var(--text-muted);
}

.interest-cost {
  color: var(--danger);
  font-weight: 700;
}

.payoff-row.highlight {
  background: rgba(16, 185, 129, 0.1);
  margin: 0.5rem -0.5rem;
  padding: 0.5rem;
  border-radius: 6px;
}

.fast-payoff {
  color: var(--success);
  font-weight: 700;
}

.payoff-row.savings {
  margin-top: 0.5rem;
}

.interest-saved {
  color: var(--success);
  font-weight: 700;
}

/* Add Card */
.add-card {
  border: 2px dashed var(--border);
}

.add-card h3 {
  margin-bottom: 1rem;
  color: var(--text);
}

.add-form {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.input-full {
  width: 100%;
  padding: 0.75rem;
  background: var(--bg);
  border: 1px solid var(--border);
  border-radius: 0.5rem;
  color: var(--text);
  font-size: 1rem;
}

.form-row {
  display: flex;
  gap: 0.5rem;
}

.form-row input {
  flex: 1;
  padding: 0.5rem;
  background: var(--bg);
  border: 1px solid var(--border);
  border-radius: 0.25rem;
  color: var(--text);
  font-size: 0.9rem;
}

.form-actions {
  display: flex;
  gap: 0.5rem;
}

.btn-add-confirm,
.btn-cancel {
  padding: 0.5rem 1rem;
  border: none;
  border-radius: 0.25rem;
  cursor: pointer;
  font-weight: 600;
}

.btn-add-confirm {
  background: var(--success);
  color: white;
}

.btn-cancel {
  background: var(--border);
  color: var(--text);
}

.add-card-button {
  display: flex;
  align-items: center;
  justify-content: center;
  background: var(--bg-light);
  border: 2px dashed var(--border);
  border-radius: 1rem;
  padding: 3rem;
  cursor: pointer;
  color: var(--text-muted);
  font-weight: 600;
  transition: all 0.2s;
}

.add-card-button:hover {
  border-color: var(--primary);
  color: var(--primary);
}
</style>
