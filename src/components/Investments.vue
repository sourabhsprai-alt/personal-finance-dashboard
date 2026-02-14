<template>
  <div class="investments">
    <div class="page-banner accent-success">
      <div class="banner-label">Total Investments</div>
      <div class="banner-value success">{{ formatDisplay(totalInvestments, displayCurrency) }}</div>
      <div class="banner-secondary">{{ formatDisplay(totalInvestments, displayCurrency === 'EUR' ? 'INR' : 'EUR') }}</div>
    </div>

    <!-- India Investments -->
    <div class="investment-group">
      <div class="group-header" @click="toggleGroup('india')">
        <h3>🇮🇳 India</h3>
        <div class="group-total">{{ formatDisplay(indiaTotal, displayCurrency) }}</div>
        <span class="toggle-icon">{{ expandedGroups.india ? '▼' : '▶' }}</span>
      </div>
      
      <div v-if="expandedGroups.india" class="group-items">
        <div v-for="inv in indiaInvestments" :key="inv.id" class="investment-item">
          <div class="item-name">{{ inv.name }}</div>
          <div class="item-value">
            <input 
              type="number" 
              :value="inv.amount" 
              @change="handleUpdate(inv.id, $event.target.value)"
              class="editable-value"
            />
            <span class="currency">INR</span>
          </div>
          <button 
            @click="toggleIlliquid(inv.id, !inv.is_illiquid)" 
            class="btn-illiquid"
            :class="{ active: inv.is_illiquid }"
          >
            {{ inv.is_illiquid ? '🔒 Illiquid' : '💧 Liquid' }}
          </button>
          <button @click="deleteInvestment(inv.id)" class="btn-delete">🗑️</button>
        </div>
        
        <!-- Add New India Investment -->
        <div class="add-item-form" v-if="showAddIndia">
          <input v-model="newIndia.name" placeholder="Name" class="input-name" />
          <input v-model.number="newIndia.amount" type="number" placeholder="Amount (INR)" class="input-amount" />
          <label class="checkbox-label">
            <input type="checkbox" v-model="newIndia.is_illiquid" /> Illiquid
          </label>
          <button @click="addIndiaInvestment" class="btn-add-confirm">Add</button>
          <button @click="showAddIndia = false" class="btn-cancel">Cancel</button>
        </div>
        <button v-else @click="showAddIndia = true" class="btn-add-new">+ Add India Investment</button>
      </div>
    </div>

    <!-- Germany Investments -->
    <div class="investment-group">
      <div class="group-header" @click="toggleGroup('germany')">
        <h3>🇩🇪 Germany</h3>
        <div class="group-total">{{ formatDisplay(germanyTotal, displayCurrency) }}</div>
        <span class="toggle-icon">{{ expandedGroups.germany ? '▼' : '▶' }}</span>
      </div>
      
      <div v-if="expandedGroups.germany" class="group-items">
        <div v-for="inv in germanyInvestments" :key="inv.id" class="investment-item" :class="{ 'esop-item': isEsop(inv) }">
          <div class="item-name">{{ inv.name }}</div>
          
          <!-- ESOP Special Display -->
          <template v-if="isEsop(inv)">
            <div class="esop-details">
              <div class="esop-field">
                <label>Total Shares</label>
                <input 
                  type="number" 
                  :value="inv.esop_total_shares || 0" 
                  @change="updateEsopField(inv.id, 'esop_total_shares', $event.target.value)"
                  class="esop-input"
                />
              </div>
              <div class="esop-field">
                <label>Vested</label>
                <input 
                  type="number" 
                  :value="inv.esop_vested_shares || 0" 
                  @change="updateEsopField(inv.id, 'esop_vested_shares', $event.target.value)"
                  class="esop-input"
                />
              </div>
              <div class="esop-field">
                <label>€/Share</label>
                <input 
                  type="number" 
                  step="0.01"
                  :value="inv.esop_share_value || 0" 
                  @change="updateEsopField(inv.id, 'esop_share_value', $event.target.value)"
                  class="esop-input"
                />
              </div>
              <div class="esop-value">
                <label>Vested Value</label>
                <span class="value-display">€{{ maskNumber(calculateEsopValue(inv)) }}</span>
              </div>
            </div>
          </template>
          
          <!-- Regular Investment Display -->
          <template v-else>
            <div class="item-value">
              <input 
                type="number" 
                :value="inv.amount" 
                @change="handleUpdate(inv.id, $event.target.value)"
                class="editable-value"
              />
              <span class="currency">EUR</span>
            </div>
          </template>
          
          <button 
            @click="toggleIlliquid(inv.id, !inv.is_illiquid)" 
            class="btn-illiquid"
            :class="{ active: inv.is_illiquid }"
          >
            {{ inv.is_illiquid ? '🔒 Illiquid' : '💧 Liquid' }}
          </button>
          <button @click="deleteInvestment(inv.id)" class="btn-delete">🗑️</button>
        </div>
        
        <!-- Add New Germany Investment -->
        <div class="add-item-form" v-if="showAddGermany">
          <input v-model="newGermany.name" placeholder="Name" class="input-name" />
          <input v-model.number="newGermany.amount" type="number" placeholder="Amount (EUR)" class="input-amount" />
          <label class="checkbox-label">
            <input type="checkbox" v-model="newGermany.is_illiquid" /> Illiquid
          </label>
          <button @click="addGermanyInvestment" class="btn-add-confirm">Add</button>
          <button @click="showAddGermany = false" class="btn-cancel">Cancel</button>
        </div>
        <button v-else @click="showAddGermany = true" class="btn-add-new">+ Add Germany Investment</button>
      </div>
    </div>

    <!-- Crypto Investments -->
    <div class="investment-group">
      <div class="group-header" @click="toggleGroup('crypto')">
        <h3>🪙 Crypto</h3>
        <div class="group-total">{{ formatDisplay(cryptoTotal, displayCurrency) }}</div>
        <span class="toggle-icon">{{ expandedGroups.crypto ? '▼' : '▶' }}</span>
      </div>
      
      <div v-if="expandedGroups.crypto" class="group-items">
        <div v-for="inv in cryptoInvestments" :key="inv.id" class="investment-item">
          <div class="item-name">{{ inv.name }}</div>
          <div class="item-value">
            <input 
              type="number" 
              :value="inv.amount" 
              @change="handleUpdate(inv.id, $event.target.value)"
              class="editable-value"
            />
            <span class="currency">USD</span>
          </div>
          <button 
            @click="toggleIlliquid(inv.id, !inv.is_illiquid)" 
            class="btn-illiquid"
            :class="{ active: inv.is_illiquid }"
          >
            {{ inv.is_illiquid ? '🔒 Illiquid' : '💧 Liquid' }}
          </button>
          <span v-if="inv.is_locked" class="badge-locked">Locked</span>
          <span v-if="inv.invested_amount" class="invested-info">Cost: ${{ maskNumber(inv.invested_amount) }}</span>
          <button @click="deleteInvestment(inv.id)" class="btn-delete">🗑️</button>
        </div>
        
        <!-- Add New Crypto -->
        <div class="add-item-form" v-if="showAddCrypto">
          <input v-model="newCrypto.name" placeholder="Token/Asset Name" class="input-name" />
          <input v-model.number="newCrypto.amount" type="number" placeholder="Current Value (USD)" class="input-amount" />
          <input v-model.number="newCrypto.invested_amount" type="number" placeholder="Cost Basis (USD)" class="input-amount" />
          <label class="checkbox-label">
            <input type="checkbox" v-model="newCrypto.is_locked" /> Locked
          </label>
          <button @click="addCryptoInvestment" class="btn-add-confirm">Add</button>
          <button @click="showAddCrypto = false" class="btn-cancel">Cancel</button>
        </div>
        <button v-else @click="showAddCrypto = true" class="btn-add-new">+ Add Crypto Asset</button>
      </div>
    </div>

    <!-- Savings -->
    <div class="investment-group">
      <div class="group-header" @click="toggleGroup('savings')">
        <h3>💰 Savings</h3>
        <div class="group-total">{{ formatDisplay(savingsTotal, displayCurrency) }}</div>
        <span class="toggle-icon">{{ expandedGroups.savings ? '▼' : '▶' }}</span>
      </div>
      
      <div v-if="expandedGroups.savings" class="group-items">
        <div v-for="sav in savingsList" :key="sav.id" class="investment-item">
          <div class="item-name">{{ sav.name }}</div>
          <div class="item-value">
            <input 
              type="number" 
              :value="sav.amount" 
              @change="handleUpdateSaving(sav.id, $event.target.value)"
              class="editable-value"
            />
            <span class="currency">{{ sav.currency }}</span>
          </div>
          <button @click="deleteSaving(sav.id)" class="btn-delete">🗑️</button>
        </div>
        
        <!-- Add New Saving -->
        <div class="add-item-form" v-if="showAddSaving">
          <input v-model="newSaving.name" placeholder="Account Name" class="input-name" />
          <input v-model.number="newSaving.amount" type="number" placeholder="Amount" class="input-amount" />
          <select v-model="newSaving.currency" class="input-select">
            <option value="INR">INR</option>
            <option value="EUR">EUR</option>
            <option value="USD">USD</option>
          </select>
          <button @click="addSaving" class="btn-add-confirm">Add</button>
          <button @click="showAddSaving = false" class="btn-cancel">Cancel</button>
        </div>
        <button v-else @click="showAddSaving = true" class="btn-add-new">+ Add Savings Account</button>
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
  name: 'Investments',
  props: {
    displayCurrency: String,
    valuesHidden: { type: Boolean, default: false }
  },
  setup(props) {
    const { user } = useAuth()
    const {
      investments,
      savings,
      settings,
      convertToEUR,
      formatCurrency,
      fetchAllData
    } = useFinanceData()

    const expandedGroups = ref({
      india: true,
      germany: true,
      crypto: true,
      savings: true
    })

    // Add item toggles
    const showAddIndia = ref(false)
    const showAddGermany = ref(false)
    const showAddCrypto = ref(false)
    const showAddSaving = ref(false)

    // New item forms
    const newIndia = ref({ name: '', amount: 0, is_illiquid: false })
    const newGermany = ref({ name: '', amount: 0, is_illiquid: false })
    const newCrypto = ref({ name: '', amount: 0, invested_amount: 0, is_locked: false })
    const newSaving = ref({ name: '', amount: 0, currency: 'INR' })

    const toggleGroup = (group) => {
      expandedGroups.value[group] = !expandedGroups.value[group]
    }

    const savingsList = computed(() => savings.value || [])

    const indiaInvestments = computed(() => {
      return (investments.value || []).filter(inv => inv.category === 'india')
    })

    const germanyInvestments = computed(() => {
      return (investments.value || []).filter(inv => inv.category === 'germany')
    })

    const cryptoInvestments = computed(() => {
      return (investments.value || []).filter(inv => inv.category === 'crypto')
    })

    const totalInvestments = computed(() => {
      let total = 0
      if (investments.value) {
        investments.value.forEach(inv => {
          total += convertToEUR(inv.amount, inv.currency)
        })
      }
      if (savings.value) {
        savings.value.forEach(sav => {
          total += convertToEUR(sav.amount, sav.currency)
        })
      }
      return total
    })

    const indiaTotal = computed(() => {
      return indiaInvestments.value.reduce((sum, inv) => {
        return sum + convertToEUR(inv.amount, inv.currency)
      }, 0)
    })

    const germanyTotal = computed(() => {
      return germanyInvestments.value.reduce((sum, inv) => {
        return sum + convertToEUR(inv.amount, inv.currency)
      }, 0)
    })

    const cryptoTotal = computed(() => {
      return cryptoInvestments.value.reduce((sum, inv) => {
        return sum + convertToEUR(inv.amount, inv.currency)
      }, 0)
    })

    const savingsTotal = computed(() => {
      return savingsList.value.reduce((sum, sav) => {
        return sum + convertToEUR(sav.amount, sav.currency)
      }, 0)
    })

    const formatDisplay = (amount, currency) => {
      if (props.valuesHidden) return '••••••'
      if (currency === 'EUR') {
        return formatCurrency(amount, 'EUR')
      } else {
        const rate = settings.value?.eur_to_inr || 107.58
        return formatCurrency(amount * rate, 'INR')
      }
    }
    const maskNumber = (num) => props.valuesHidden ? '••••' : num.toLocaleString()

    // ESOP helpers
    const isEsop = (inv) => {
      return inv.name && inv.name.toLowerCase().includes('esop')
    }

    const calculateEsopValue = (inv) => {
      const vested = inv.esop_vested_shares || 0
      const shareValue = inv.esop_share_value || 0
      return Math.round(vested * shareValue * 100) / 100
    }

    const updateEsopField = async (id, field, value) => {
      try {
        const inv = investments.value.find(i => i.id === id)
        const updates = { [field]: parseFloat(value) || 0 }
        
        // Also update the amount to reflect vested value
        const vested = field === 'esop_vested_shares' ? parseFloat(value) : (inv?.esop_vested_shares || 0)
        const shareValue = field === 'esop_share_value' ? parseFloat(value) : (inv?.esop_share_value || 0)
        updates.amount = Math.round(vested * shareValue * 100) / 100

        await supabase
          .from('investments')
          .update(updates)
          .eq('id', id)
        await fetchAllData()
      } catch (error) {
        console.error('Error updating ESOP field:', error)
      }
    }

    const handleUpdate = async (id, value) => {
      try {
        await supabase
          .from('investments')
          .update({ amount: parseFloat(value) })
          .eq('id', id)
        await fetchAllData()
      } catch (error) {
        console.error('Error updating investment:', error)
      }
    }

    const handleUpdateSaving = async (id, value) => {
      try {
        await supabase
          .from('savings')
          .update({ amount: parseFloat(value) })
          .eq('id', id)
        await fetchAllData()
      } catch (error) {
        console.error('Error updating saving:', error)
      }
    }

    const deleteInvestment = async (id) => {
      if (!confirm('Delete this investment?')) return
      try {
        await supabase.from('investments').delete().eq('id', id)
        await fetchAllData()
      } catch (error) {
        console.error('Error deleting investment:', error)
      }
    }

    const toggleIlliquid = async (id, value) => {
      try {
        await supabase
          .from('investments')
          .update({ is_illiquid: value })
          .eq('id', id)
        await fetchAllData()
      } catch (error) {
        console.error('Error toggling illiquid:', error)
      }
    }

    const deleteSaving = async (id) => {
      if (!confirm('Delete this savings account?')) return
      try {
        await supabase.from('savings').delete().eq('id', id)
        await fetchAllData()
      } catch (error) {
        console.error('Error deleting saving:', error)
      }
    }

    const addIndiaInvestment = async () => {
      if (!user.value || !newIndia.value.name) return
      try {
        await supabase.from('investments').insert({
          user_id: user.value.id,
          category: 'india',
          name: newIndia.value.name,
          amount: newIndia.value.amount,
          currency: 'INR',
          is_illiquid: newIndia.value.is_illiquid,
          is_locked: false
        })
        newIndia.value = { name: '', amount: 0, is_illiquid: false }
        showAddIndia.value = false
        await fetchAllData()
      } catch (error) {
        console.error('Error adding investment:', error)
      }
    }

    const addGermanyInvestment = async () => {
      if (!user.value || !newGermany.value.name) return
      try {
        await supabase.from('investments').insert({
          user_id: user.value.id,
          category: 'germany',
          name: newGermany.value.name,
          amount: newGermany.value.amount,
          currency: 'EUR',
          is_illiquid: newGermany.value.is_illiquid,
          is_locked: false
        })
        newGermany.value = { name: '', amount: 0, is_illiquid: false }
        showAddGermany.value = false
        await fetchAllData()
      } catch (error) {
        console.error('Error adding investment:', error)
      }
    }

    const addCryptoInvestment = async () => {
      if (!user.value || !newCrypto.value.name) return
      try {
        await supabase.from('investments').insert({
          user_id: user.value.id,
          category: 'crypto',
          name: newCrypto.value.name,
          amount: newCrypto.value.amount,
          currency: 'USD',
          is_illiquid: false,
          is_locked: newCrypto.value.is_locked,
          invested_amount: newCrypto.value.invested_amount || null
        })
        newCrypto.value = { name: '', amount: 0, invested_amount: 0, is_locked: false }
        showAddCrypto.value = false
        await fetchAllData()
      } catch (error) {
        console.error('Error adding crypto:', error)
      }
    }

    const addSaving = async () => {
      if (!user.value || !newSaving.value.name) return
      try {
        await supabase.from('savings').insert({
          user_id: user.value.id,
          name: newSaving.value.name,
          amount: newSaving.value.amount,
          currency: newSaving.value.currency
        })
        newSaving.value = { name: '', amount: 0, currency: 'INR' }
        showAddSaving.value = false
        await fetchAllData()
      } catch (error) {
        console.error('Error adding saving:', error)
      }
    }

    return {
      expandedGroups,
      toggleGroup,
      savingsList,
      indiaInvestments,
      germanyInvestments,
      cryptoInvestments,
      totalInvestments,
      indiaTotal,
      germanyTotal,
      cryptoTotal,
      savingsTotal,
      formatDisplay,
      maskNumber,
      handleUpdate,
      handleUpdateSaving,
      deleteInvestment,
      deleteSaving,
      toggleIlliquid,
      showAddIndia,
      showAddGermany,
      showAddCrypto,
      showAddSaving,
      newIndia,
      newGermany,
      newCrypto,
      newSaving,
      addIndiaInvestment,
      addGermanyInvestment,
      addCryptoInvestment,
      addSaving,
      // ESOP support
      isEsop,
      calculateEsopValue,
      updateEsopField
    }
  }
}
</script>

<style scoped>
.investments {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}

/* Summary card now uses global .page-banner styles */

.investment-group {
  background: var(--bg-light);
  border-radius: 1rem;
  border: 2px solid var(--border);
  overflow: hidden;
}

.group-header {
  padding: 1.5rem;
  display: flex;
  align-items: center;
  gap: 1rem;
  cursor: pointer;
  transition: background 0.2s;
}

.group-header:hover {
  background: rgba(255, 255, 255, 0.05);
}

.group-header h3 {
  flex: 1;
  font-size: 1.3rem;
}

.group-total {
  font-size: 1.2rem;
  font-weight: 700;
  color: var(--primary);
}

.toggle-icon {
  font-size: 1.2rem;
  color: var(--text-muted);
}

.group-items {
  padding: 0 1.5rem 1.5rem;
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

.investment-item {
  display: flex;
  align-items: center;
  gap: 1rem;
  padding: 1rem;
  background: var(--bg);
  border-radius: 0.5rem;
  flex-wrap: wrap;
}

.item-name {
  flex: 1;
  min-width: 150px;
  font-weight: 600;
}

.item-value {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.editable-value {
  width: 120px;
  padding: 0.5rem;
  background: var(--bg-light);
  border: 1px solid var(--border);
  border-radius: 0.25rem;
  color: var(--text);
  font-size: 1rem;
  font-weight: 600;
}

.editable-value:focus {
  outline: none;
  border-color: var(--primary);
}

.currency {
  font-weight: 600;
  color: var(--text-muted);
}

.btn-illiquid {
  padding: 0.35rem 0.6rem;
  border-radius: 0.35rem;
  font-size: 0.75rem;
  font-weight: 600;
  border: 1px solid var(--border);
  background: var(--bg-light);
  color: var(--text-muted);
  cursor: pointer;
  transition: all 0.2s;
  white-space: nowrap;
}

.btn-illiquid:hover {
  border-color: var(--primary);
}

.btn-illiquid.active {
  background: var(--warning);
  border-color: var(--warning);
  color: white;
}

.badge-locked {
  padding: 0.25rem 0.5rem;
  border-radius: 0.25rem;
  font-size: 0.8rem;
  font-weight: 600;
  background: var(--danger);
  color: white;
}

.invested-info {
  font-size: 0.85rem;
  color: var(--text-muted);
  font-style: italic;
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

/* Add Item Forms */
.add-item-form {
  display: flex;
  flex-wrap: wrap;
  gap: 0.75rem;
  padding: 1rem;
  background: var(--bg);
  border-radius: 0.5rem;
  border: 2px dashed var(--border);
}

.input-name,
.input-amount,
.input-select {
  padding: 0.5rem;
  background: var(--bg-light);
  border: 1px solid var(--border);
  border-radius: 0.25rem;
  color: var(--text);
  font-size: 0.9rem;
}

.input-name {
  flex: 1;
  min-width: 150px;
}

.input-amount {
  width: 120px;
}

.input-select {
  width: 80px;
}

.checkbox-label {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  color: var(--text-muted);
  font-size: 0.9rem;
}

.btn-add-confirm,
.btn-cancel {
  padding: 0.5rem 1rem;
  border: none;
  border-radius: 0.25rem;
  cursor: pointer;
  font-weight: 600;
  font-size: 0.9rem;
}

.btn-add-confirm {
  background: var(--success);
  color: white;
}

.btn-cancel {
  background: var(--border);
  color: var(--text);
}

.btn-add-new {
  padding: 0.75rem;
  background: transparent;
  border: 2px dashed var(--border);
  border-radius: 0.5rem;
  color: var(--text-muted);
  cursor: pointer;
  font-weight: 600;
  transition: all 0.2s;
}

.btn-add-new:hover {
  border-color: var(--primary);
  color: var(--primary);
}

/* ESOP Styles */
.esop-item {
  flex-direction: column;
  align-items: stretch !important;
}

.esop-item .item-name {
  margin-bottom: 0.75rem;
  font-size: 1.1rem;
}

.esop-details {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 0.75rem;
  width: 100%;
  margin-bottom: 0.75rem;
}

.esop-field {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}

.esop-field label {
  font-size: 0.7rem;
  color: var(--text-muted);
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

.esop-input {
  padding: 0.5rem;
  background: var(--bg-light);
  border: 1px solid var(--border);
  border-radius: 0.25rem;
  color: var(--text);
  font-size: 1rem;
  font-weight: 600;
  width: 100%;
}

.esop-input:focus {
  outline: none;
  border-color: var(--primary);
}

.esop-value {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}

.esop-value label {
  font-size: 0.7rem;
  color: var(--text-muted);
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

.esop-value .value-display {
  font-size: 1.2rem;
  font-weight: 700;
  color: var(--success);
  padding: 0.35rem 0;
}

@media (max-width: 768px) {
  .investment-item {
    flex-direction: column;
    align-items: flex-start;
  }
  
  .item-value {
    width: 100%;
  }

  .esop-details {
    grid-template-columns: repeat(2, 1fr);
  }
}
</style>
