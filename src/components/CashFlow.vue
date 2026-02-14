<template>
  <div class="cashflow">
    <!-- Summary Cards -->
    <div class="page-banner-row">
      <div class="page-banner accent-success">
        <div class="banner-label">Monthly Income</div>
        <div class="banner-value success">€{{ maskNumber(totalIncome) }}</div>
      </div>
      <div class="page-banner accent-danger">
        <div class="banner-label">Monthly Expenses</div>
        <div class="banner-value danger">€{{ maskNumber(totalExpenses) }}</div>
      </div>
      <div class="page-banner" :class="surplus >= 0 ? 'accent-primary' : 'accent-danger'">
        <div class="banner-label">Monthly Surplus</div>
        <div class="banner-value" :class="surplus >= 0 ? 'primary' : 'danger'">€{{ maskNumber(surplus) }}</div>
      </div>
    </div>

    <!-- Income Section -->
    <div class="section glass-card">
      <div class="section-header">
        <h2>💰 Income Sources</h2>
        <button @click="showAddIncome = true" class="btn-add" v-if="!showAddIncome">+ Add</button>
      </div>

      <div class="items-list">
        <div v-for="inc in incomeList" :key="inc.id" class="list-item">
          <div class="item-info">
            <span class="item-name">{{ inc.name }}</span>
            <span class="item-tag" v-if="inc.is_recurring">Recurring</span>
          </div>
          <div class="item-actions">
            <input 
              type="number" 
              :value="inc.amount" 
              @change="updateIncome(inc.id, $event.target.value)"
              class="amount-input"
            />
            <span class="currency-label">EUR</span>
            <button @click="deleteIncome(inc.id)" class="btn-delete">×</button>
          </div>
        </div>

        <!-- Add Income Form -->
        <div v-if="showAddIncome" class="add-form">
          <input v-model="newIncome.name" placeholder="Income source name" class="input-text" />
          <input v-model.number="newIncome.amount" type="number" placeholder="Amount (EUR)" class="input-number" />
          <label class="checkbox">
            <input type="checkbox" v-model="newIncome.is_recurring" />
            <span>Recurring</span>
          </label>
          <div class="form-buttons">
            <button @click="addIncome" class="btn-confirm">Add</button>
            <button @click="showAddIncome = false" class="btn-cancel">Cancel</button>
          </div>
        </div>
      </div>
    </div>

    <!-- Monthly Expenses Section -->
    <div class="section glass-card">
      <div class="section-header">
        <h2>📤 Monthly Expenses</h2>
        <button @click="openAddExpense('monthly')" class="btn-add" v-if="!showAddExpense">+ Add</button>
      </div>

      <!-- Monthly Expense Categories (only show non-empty) -->
      <div v-for="cat in monthlyCategories" :key="cat.key" class="expense-category">
        <div class="category-header">
          <span class="category-icon">{{ cat.icon }}</span>
          <span class="category-name">{{ cat.name }}</span>
          <span class="category-total">€{{ maskNumber(getMonthlyOnlyCategoryTotal(cat.key)) }}</span>
        </div>
        
        <div class="items-list">
          <div v-for="exp in getMonthlyExpensesByCategory(cat.key)" :key="exp.id" class="list-item">
            <div class="item-info">
              <span class="item-name">{{ exp.name }}</span>
            </div>
            <div class="item-actions">
              <input 
                type="number" 
                :value="exp.amount" 
                @change="updateExpense(exp.id, $event.target.value)"
                class="amount-input"
              />
              <span class="currency-label">/mo</span>
              <button @click="deleteExpense(exp.id)" class="btn-delete">×</button>
            </div>
          </div>
        </div>
      </div>

      <div v-if="monthlyCategories.length === 0" class="empty-state">
        <p>No monthly expenses yet</p>
      </div>

      <!-- Add Monthly Expense Form -->
      <div v-if="showAddExpense && newExpense.frequency === 'monthly'" class="add-form">
        <input v-model="newExpense.name" placeholder="Expense name" class="input-text" />
        <input v-model.number="newExpense.amount" type="number" placeholder="Amount" class="input-number" />
        <select v-model="newExpense.category" class="input-select">
          <option v-for="cat in expenseCategories" :key="cat.key" :value="cat.key">{{ cat.name }}</option>
        </select>
        <div class="form-buttons">
          <button @click="addExpense" class="btn-confirm">Add</button>
          <button @click="showAddExpense = false" class="btn-cancel">Cancel</button>
        </div>
      </div>
    </div>

    <!-- Yearly/Quarterly Payments Section -->
    <div class="section glass-card" v-if="yearlyQuarterlyExpenses.length > 0 || showAddExpense && newExpense.frequency !== 'monthly'">
      <div class="section-header">
        <h2>📅 Yearly & Quarterly Payments</h2>
        <button @click="openAddExpense('yearly')" class="btn-add" v-if="!showAddExpense">+ Add</button>
      </div>

      <div class="yearly-total-banner">
        <span>Total yearly cost:</span>
        <strong>€{{ maskNumber(yearlyTotal) }}/year</strong>
        <span class="monthly-equiv">(€{{ maskNumber(Math.round(yearlyTotal / 12)) }}/mo equivalent)</span>
      </div>

      <div class="items-list">
        <div v-for="exp in yearlyQuarterlyExpenses" :key="exp.id" class="list-item yearly-item">
          <div class="item-info">
            <span class="item-name">{{ exp.name }}</span>
            <span class="item-tag" :class="exp.frequency">{{ exp.frequency }}</span>
            <span class="item-category">{{ getCategoryName(exp.category) }}</span>
          </div>
          <div class="item-actions">
            <input 
              type="number" 
              :value="exp.amount" 
              @change="updateExpense(exp.id, $event.target.value)"
              class="amount-input"
            />
            <span class="currency-label">{{ exp.frequency === 'quarterly' ? '/qtr' : '/yr' }}</span>
            <button @click="deleteExpense(exp.id)" class="btn-delete">×</button>
          </div>
        </div>
      </div>

      <!-- Add Yearly/Quarterly Expense Form -->
      <div v-if="showAddExpense && newExpense.frequency !== 'monthly'" class="add-form">
        <input v-model="newExpense.name" placeholder="Payment name" class="input-text" />
        <input v-model.number="newExpense.amount" type="number" placeholder="Amount" class="input-number" />
        <select v-model="newExpense.category" class="input-select">
          <option v-for="cat in expenseCategories" :key="cat.key" :value="cat.key">{{ cat.name }}</option>
        </select>
        <select v-model="newExpense.frequency" class="input-select">
          <option value="quarterly">Quarterly</option>
          <option value="yearly">Yearly</option>
        </select>
        <div class="form-buttons">
          <button @click="addExpense" class="btn-confirm">Add</button>
          <button @click="showAddExpense = false" class="btn-cancel">Cancel</button>
        </div>
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
  name: 'CashFlow',
  props: {
    valuesHidden: { type: Boolean, default: false }
  },
  setup(props) {
    const { user } = useAuth()
    const { incomeSources, expenseItems, getTotalMonthlyIncome, getTotalMonthlyExpenses, getMonthlySurplus, fetchAllData } = useFinanceData()

    const showAddIncome = ref(false)
    const showAddExpense = ref(false)
    const newIncome = ref({ name: '', amount: 0, is_recurring: true })
    const newExpense = ref({ name: '', amount: 0, category: 'other', frequency: 'monthly' })

    const incomeList = computed(() => incomeSources.value || [])
    const expenseList = computed(() => expenseItems.value || [])
    const totalIncome = computed(() => Math.round(getTotalMonthlyIncome.value))
    const totalExpenses = computed(() => Math.round(getTotalMonthlyExpenses.value))
    const surplus = computed(() => Math.round(getMonthlySurplus.value))
    const maskNumber = (num) => props.valuesHidden ? '••••' : num.toLocaleString()

    const expenseCategories = [
      { key: 'housing', name: 'Housing', icon: '🏠' },
      { key: 'utilities', name: 'Utilities', icon: '⚡' },
      { key: 'transport', name: 'Transport', icon: '🚗' },
      { key: 'food', name: 'Food', icon: '🍽️' },
      { key: 'insurance', name: 'Insurance', icon: '🛡️' },
      { key: 'loans', name: 'Loans', icon: '💳' },
      { key: 'other', name: 'Other', icon: '📦' }
    ]

    // Get only monthly expenses by category
    const getMonthlyExpensesByCategory = (category) => {
      return expenseList.value.filter(e => e.category === category && e.frequency === 'monthly')
    }

    // Get monthly-only total for a category
    const getMonthlyOnlyCategoryTotal = (category) => {
      return getMonthlyExpensesByCategory(category).reduce((sum, e) => sum + e.amount, 0)
    }

    // Categories that have monthly expenses (hide empty ones)
    const monthlyCategories = computed(() => {
      return expenseCategories.filter(cat => getMonthlyExpensesByCategory(cat.key).length > 0)
    })

    // Yearly and quarterly expenses (separate list)
    const yearlyQuarterlyExpenses = computed(() => {
      return expenseList.value.filter(e => e.frequency === 'yearly' || e.frequency === 'quarterly')
    })

    // Total yearly cost
    const yearlyTotal = computed(() => {
      return yearlyQuarterlyExpenses.value.reduce((sum, e) => {
        if (e.frequency === 'quarterly') return sum + (e.amount * 4)
        return sum + e.amount
      }, 0)
    })

    // Get category name by key
    const getCategoryName = (key) => {
      const cat = expenseCategories.find(c => c.key === key)
      return cat ? cat.name : key
    }

    // Open add expense form with preset frequency
    const openAddExpense = (frequency) => {
      newExpense.value.frequency = frequency
      showAddExpense.value = true
    }

    const getExpensesByCategory = (category) => {
      return expenseList.value.filter(e => e.category === category)
    }

    const getCategoryTotal = (category) => {
      return getExpensesByCategory(category).reduce((sum, e) => {
        let monthly = e.amount
        if (e.frequency === 'quarterly') monthly = e.amount / 3
        if (e.frequency === 'yearly') monthly = e.amount / 12
        return sum + monthly
      }, 0)
    }

    const updateIncome = async (id, value) => {
      await supabase.from('income_sources').update({ amount: parseFloat(value) }).eq('id', id)
      await fetchAllData()
    }

    const deleteIncome = async (id) => {
      if (!confirm('Delete this income source?')) return
      await supabase.from('income_sources').delete().eq('id', id)
      await fetchAllData()
    }

    const addIncome = async () => {
      if (!user.value || !newIncome.value.name) return
      await supabase.from('income_sources').insert({
        user_id: user.value.id,
        name: newIncome.value.name,
        amount: newIncome.value.amount,
        currency: 'EUR',
        is_recurring: newIncome.value.is_recurring
      })
      newIncome.value = { name: '', amount: 0, is_recurring: true }
      showAddIncome.value = false
      await fetchAllData()
    }

    const updateExpense = async (id, value) => {
      await supabase.from('expense_items').update({ amount: parseFloat(value) }).eq('id', id)
      await fetchAllData()
    }

    const deleteExpense = async (id) => {
      if (!confirm('Delete this expense?')) return
      await supabase.from('expense_items').delete().eq('id', id)
      await fetchAllData()
    }

    const addExpense = async () => {
      if (!user.value || !newExpense.value.name) return
      await supabase.from('expense_items').insert({
        user_id: user.value.id,
        name: newExpense.value.name,
        amount: newExpense.value.amount,
        category: newExpense.value.category,
        frequency: newExpense.value.frequency,
        currency: 'EUR'
      })
      newExpense.value = { name: '', amount: 0, category: 'other', frequency: 'monthly' }
      showAddExpense.value = false
      await fetchAllData()
    }

    return {
      incomeList, expenseList, totalIncome, totalExpenses, surplus, maskNumber,
      expenseCategories, getExpensesByCategory, getCategoryTotal,
      getMonthlyExpensesByCategory, getMonthlyOnlyCategoryTotal, monthlyCategories,
      yearlyQuarterlyExpenses, yearlyTotal, getCategoryName, openAddExpense,
      showAddIncome, showAddExpense, newIncome, newExpense,
      updateIncome, deleteIncome, addIncome, updateExpense, deleteExpense, addExpense
    }
  }
}
</script>

<style scoped>
.cashflow {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}

/* Summary cards now use global .page-banner-row and .page-banner styles */

.section {
  padding: 1.5rem;
}

.section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1.25rem;
}

.section-header h2 {
  font-size: 1.25rem;
  font-weight: 600;
}

.btn-add {
  padding: 0.5rem 1rem;
  background: var(--primary);
  color: white;
  border: none;
  border-radius: 8px;
  font-weight: 500;
  cursor: pointer;
  font-size: 0.85rem;
}

.expense-category {
  margin-bottom: 1.5rem;
}

.category-header {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 0.75rem 0;
  border-bottom: 1px solid var(--border);
  margin-bottom: 0.75rem;
}

.category-icon {
  font-size: 1.25rem;
}

.category-name {
  flex: 1;
  font-weight: 600;
  color: var(--text-secondary);
}

.category-total {
  font-weight: 600;
  color: var(--text);
}

.items-list {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.list-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0.75rem 1rem;
  background: var(--bg-glass);
  border-radius: 10px;
}

.item-info {
  display: flex;
  align-items: center;
  gap: 0.75rem;
}

.item-name {
  font-weight: 500;
}

.item-tag {
  padding: 0.2rem 0.5rem;
  background: var(--primary);
  color: white;
  border-radius: 4px;
  font-size: 0.7rem;
  font-weight: 600;
  text-transform: uppercase;
}

.item-actions {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.amount-input {
  width: 80px;
  padding: 0.4rem 0.6rem;
  background: var(--bg-elevated);
  border: 1px solid var(--border);
  border-radius: 6px;
  color: var(--text);
  font-weight: 600;
  text-align: right;
}

.currency-label {
  font-size: 0.8rem;
  color: var(--text-muted);
  min-width: 30px;
}

.btn-delete {
  width: 24px;
  height: 24px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: transparent;
  border: none;
  color: var(--text-muted);
  cursor: pointer;
  font-size: 1.25rem;
  border-radius: 4px;
}

.btn-delete:hover {
  background: rgba(239, 68, 68, 0.2);
  color: var(--danger);
}

.add-form {
  display: flex;
  flex-wrap: wrap;
  gap: 0.75rem;
  padding: 1rem;
  background: var(--bg-glass);
  border: 1px dashed var(--border);
  border-radius: 10px;
  margin-top: 1rem;
}

.input-text, .input-number, .input-select {
  padding: 0.6rem 0.8rem;
  background: var(--bg-elevated);
  border: 1px solid var(--border);
  border-radius: 8px;
  color: var(--text);
  font-size: 0.9rem;
}

.input-text {
  flex: 1;
  min-width: 150px;
}

.input-number {
  width: 100px;
}

.input-select {
  min-width: 100px;
}

.checkbox {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  color: var(--text-secondary);
  font-size: 0.9rem;
}

.form-buttons {
  display: flex;
  gap: 0.5rem;
  width: 100%;
}

.btn-confirm {
  padding: 0.5rem 1.25rem;
  background: var(--success);
  color: white;
  border: none;
  border-radius: 6px;
  font-weight: 500;
  cursor: pointer;
}

.btn-cancel {
  padding: 0.5rem 1.25rem;
  background: transparent;
  color: var(--text-secondary);
  border: 1px solid var(--border);
  border-radius: 6px;
  font-weight: 500;
  cursor: pointer;
}

.empty-state {
  padding: 2rem;
  text-align: center;
  color: var(--text-muted);
  background: var(--bg-glass);
  border-radius: 10px;
}

.yearly-total-banner {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 1rem 1.25rem;
  background: linear-gradient(135deg, rgba(251, 191, 36, 0.1), transparent);
  border: 1px solid rgba(251, 191, 36, 0.3);
  border-radius: 10px;
  margin-bottom: 1rem;
  flex-wrap: wrap;
}

.yearly-total-banner strong {
  font-size: 1.1rem;
}

.monthly-equiv {
  color: var(--text-muted);
  font-size: 0.85rem;
}

.yearly-item {
  border-left: 3px solid var(--warning);
}

.item-category {
  font-size: 0.75rem;
  color: var(--text-muted);
  padding: 0.15rem 0.4rem;
  background: var(--bg-elevated);
  border-radius: 4px;
}

.item-tag.yearly {
  background: var(--warning);
}

.item-tag.quarterly {
  background: #8b5cf6;
}

@media (max-width: 768px) {
  .summary-row {
    grid-template-columns: 1fr;
  }
  
  .list-item {
    flex-direction: column;
    align-items: flex-start;
    gap: 0.75rem;
  }
  
  .item-actions {
    width: 100%;
    justify-content: flex-end;
  }
}
</style>
