<template>
  <div class="surplus-tab">
    <!-- Monthly Overview -->
    <div class="page-banner accent-primary overview-banner">
      <div class="overview-row">
        <div class="overview-item">
          <span class="banner-label">Monthly Income</span>
          <span class="overview-value income">€{{ maskNumber(totalIncome) }}</span>
        </div>
        <div class="overview-item">
          <span class="banner-label">Monthly Expenses</span>
          <span class="overview-value expenses">€{{ maskNumber(totalExpenses) }}</span>
        </div>
        <div class="overview-item">
          <span class="banner-label">Gross Surplus</span>
          <span class="overview-value muted">€{{ maskNumber(surplus) }}</span>
        </div>
      </div>
      <div class="overview-breakdown">
        <div class="breakdown-line">
          <span>Gross Surplus</span>
          <span>€{{ maskNumber(surplus) }}</span>
        </div>
        <div class="breakdown-line deduction">
          <span>− Monthly SIPs</span>
          <span>€{{ maskNumber(fixedInvestmentsTotalEUR) }}</span>
        </div>
        <div class="breakdown-line net">
          <span>= Available for Phase Goal</span>
          <span class="surplus">€{{ maskNumber(netSurplus) }}</span>
        </div>
      </div>
    </div>

    <!-- Fixed Monthly Investments (Always Active) -->
    <div class="section glass-card">
      <div class="section-header">
        <h2>📌 Monthly SIPs</h2>
        <div class="header-actions">
          <span class="section-badge always">Always Active</span>
          <button @click="showSIPEdit = !showSIPEdit" class="btn-edit">
            {{ showSIPEdit ? '✕ Cancel' : '✏️ Edit' }}
          </button>
        </div>
      </div>
      <p class="section-desc">Recurring investments that continue regardless of phase</p>
      
      <div class="allocation-list">
        <!-- View Mode -->
        <template v-if="!showSIPEdit">
          <div v-for="(inv, index) in fixedInvestments" :key="'view-' + index" class="allocation-row">
            <span class="alloc-icon">{{ inv.icon }}</span>
            <span class="alloc-name">{{ inv.name }}</span>
            <span class="alloc-amount">₹{{ (inv.amount || 0).toLocaleString() }}</span>
          </div>
          <div v-if="fixedInvestments.length === 0" class="empty-message">
            <p>No investments configured. Click Edit to add.</p>
          </div>
        </template>

        <!-- Edit Mode -->
        <template v-else>
          <div v-for="(inv, index) in fixedInvestments" :key="'edit-' + index" class="allocation-row editable">
            <select v-model="inv.icon" class="input-icon-small">
              <option value="📈">📈</option>
              <option value="🏦">🏦</option>
              <option value="💰">💰</option>
              <option value="🎯">🎯</option>
            </select>
            <input v-model="inv.name" class="input-name-edit" placeholder="Name" />
            <div class="sip-input-group">
              <span class="currency-symbol">₹</span>
              <input 
                type="number" 
                v-model.number="inv.amount"
                class="sip-input"
                placeholder="0"
              />
            </div>
            <button @click="removeInvestment(index)" class="btn-remove">✕</button>
          </div>
          
          <!-- Add New Investment -->
          <div class="add-sip-form">
            <select v-model="newSIP.icon" class="input-icon">
              <option value="📈">📈</option>
              <option value="🏦">🏦</option>
              <option value="💰">💰</option>
              <option value="🎯">🎯</option>
            </select>
            <input v-model="newSIP.name" placeholder="Investment Name" class="input-name" />
            <div class="sip-input-group">
              <span class="currency-symbol">₹</span>
              <input v-model.number="newSIP.amount" type="number" placeholder="Amount" class="sip-input" />
            </div>
            <button @click="addInvestment" class="btn-add" :disabled="!newSIP.name || !newSIP.amount">+ Add</button>
          </div>

          <div class="sip-actions">
            <button @click="saveFixedInvestments" class="btn-primary">💾 Save</button>
          </div>
        </template>

        <div class="allocation-total">
          <span>Total Monthly SIPs</span>
          <span>₹{{ maskNumber(fixedInvestmentsTotal) }} <span class="eur-equiv">(≈€{{ maskNumber(fixedInvestmentsTotalEUR) }})</span></span>
        </div>
      </div>
    </div>

    <!-- Phase Surplus Allocation -->
    <div class="section glass-card">
      <div class="section-header">
        <h2>{{ getPhaseEmoji(editingPhase) }} Phase {{ editingPhase }}: {{ getPhaseName(editingPhase) }}</h2>
        <div class="header-actions">
          <select v-model.number="editingPhase" class="phase-selector">
            <option :value="1">Phase 1</option>
            <option :value="2">Phase 2</option>
            <option :value="3">Phase 3</option>
          </select>
          <button @click="showAddForm = !showAddForm" class="btn-edit">
            {{ showAddForm ? '✕ Cancel' : '✏️ Edit' }}
          </button>
        </div>
      </div>
      <p class="section-desc">{{ getPhaseDesc(editingPhase) }}</p>
      <p v-if="editingPhase !== currentPhase" class="section-note">📝 Editing Phase {{ editingPhase }} (you're currently on Phase {{ currentPhase }})</p>

      <div class="allocation-list">
        <div v-for="alloc in allocations" :key="alloc.id" class="allocation-row editable">
          <span class="alloc-icon">{{ alloc.icon || '💰' }}</span>
          <div class="alloc-details">
            <span class="alloc-name">{{ alloc.name }}</span>
            <span class="alloc-desc" v-if="alloc.description">{{ alloc.description }}</span>
          </div>
          <span class="alloc-amount" v-if="alloc.percentage">
            {{ alloc.percentage }}% <span class="eur-equiv">= €{{ Math.round(netSurplus * alloc.percentage / 100).toLocaleString() }}</span>
          </span>
          <span class="alloc-amount" v-else>
            €{{ (alloc.amount || 0).toLocaleString() }}
          </span>
          <button v-if="showAddForm" @click="deleteAllocation(alloc.id)" class="btn-remove">✕</button>
        </div>

        <div v-if="allocations.length === 0" class="empty-message">
          <p>No allocations set. Use a template or add custom items.</p>
        </div>

        <!-- Add Form -->
        <div v-if="showAddForm" class="add-form">
          <select v-model="newAlloc.icon" class="input-icon">
            <option value="💳">💳</option>
            <option value="📈">📈</option>
            <option value="🛡️">🛡️</option>
            <option value="💰">💰</option>
            <option value="💵">💵</option>
            <option value="🎯">🎯</option>
          </select>
          <input v-model="newAlloc.name" placeholder="Name" class="input-name" />
          <input v-model.number="newAlloc.percentage" type="number" placeholder="%" class="input-pct" />
          <span class="pct-label">%</span>
          <button @click="addAllocation" class="btn-add">+ Add</button>
        </div>

        <!-- Quick Templates -->
        <div v-if="showAddForm && allocations.length === 0" class="templates">
          <p class="templates-label">Quick templates:</p>
          <div class="template-btns">
            <button @click="applyTemplate('phase1')">Phase 1: CC Debt</button>
            <button @click="applyTemplate('phase2')">Phase 2: Buffer</button>
            <button @click="applyTemplate('phase3')">Phase 3: Growth</button>
          </div>
        </div>

        <div class="allocation-total">
          <span>Phase Allocation</span>
          <span :class="{ warning: allocatedPercent > 100 }">
            €{{ maskNumber(totalAllocated) }} 
            <span class="eur-equiv">({{ allocatedPercent.toFixed(0) }}% of €{{ maskNumber(netSurplus) }} available)</span>
          </span>
        </div>
      </div>
    </div>

    <!-- Goal Progress -->
    <div class="section glass-card">
      <div class="section-header">
        <h2>🎯 Goal Progress</h2>
      </div>

      <!-- Phase 1: CC Debt -->
      <div v-if="currentPhase === 1" class="goal-card">
        <div class="goal-header">
          <span class="goal-name">💳 Credit Card Debt Payoff</span>
          <span class="goal-target">18% APR - Priority #1</span>
        </div>
        
        <div class="goal-progress-bar">
          <div class="progress-track">
            <div class="progress-fill" :style="{ width: ccDebtProgress + '%' }"></div>
          </div>
          <div class="progress-labels">
            <span>€{{ ccDebtPaid.toLocaleString() }} paid</span>
            <span>€{{ ccDebtTarget.toLocaleString() }} total</span>
          </div>
        </div>
        
        <div class="goal-paid-section">
          <div v-if="!editingCCPaid" class="paid-display">
            <span class="paid-label">Amount paid this phase:</span>
            <span class="paid-value">€{{ ccDebtPaid.toLocaleString() }}</span>
            <button @click="startEditCCPaid" class="btn-edit-small">✏️ Update</button>
          </div>
          <div v-else class="paid-edit">
            <label>Amount paid (€):</label>
            <input 
              v-model.number="tempCCPaid" 
              type="number" 
              class="input-paid"
              @keyup.enter="saveCCPaid"
            />
            <button @click="saveCCPaid" class="btn-save-small">Save</button>
            <button @click="cancelEditCCPaid" class="btn-cancel-small">Cancel</button>
          </div>
        </div>
        
        <div class="goal-projection">
          <p v-if="ccDebtRemaining > 0">
            Remaining: <strong>€{{ ccDebtRemaining.toLocaleString() }}</strong>
            <span v-if="totalAllocated > 0"> (~{{ Math.ceil(ccDebtRemaining / totalAllocated) }} months at €{{ maskNumber(totalAllocated) }}/mo)</span>
          </p>
          <p class="projection-result success" v-else>✅ Credit card debt cleared!</p>
        </div>
      </div>

      <!-- Phase 2: Buffer -->
      <div v-if="currentPhase === 2" class="goal-card">
        <div class="goal-header">
          <span class="goal-name">🛡️ Emergency Buffer</span>
          <span class="goal-target">Target: €15,000</span>
        </div>
        <div class="goal-progress-bar">
          <div class="progress-track">
            <div class="progress-fill" :style="{ width: Math.min(bufferProgress, 100) + '%' }"></div>
          </div>
          <div class="progress-labels">
            <span>€{{ bufferCurrent.toLocaleString() }}</span>
            <span>€15,000</span>
          </div>
        </div>
        <div class="goal-projection">
          <p>Monthly contribution: <strong>€{{ Math.round(totalAllocated * 0.8).toLocaleString() }}</strong> (80%)</p>
          <p class="projection-result" v-if="bufferCurrent < 15000">
            ~{{ Math.ceil((15000 - bufferCurrent) / (totalAllocated * 0.8)) }} months to reach goal
          </p>
          <p class="projection-result success" v-else>✅ Buffer goal reached!</p>
        </div>
      </div>

      <!-- Phase 3: Growth -->
      <div v-if="currentPhase === 3" class="goal-card">
        <div class="goal-header">
          <span class="goal-name">🚀 Wealth Building</span>
          <span class="goal-target">Balanced Growth Strategy</span>
        </div>
        <div class="goal-breakdown">
          <div class="breakdown-item">
            <span>📈 Investments</span>
            <span>Building long-term wealth</span>
          </div>
          <div class="breakdown-item">
            <span>🛡️ Crash Fund</span>
            <span>Ready to buy dips</span>
          </div>
          <div class="breakdown-item">
            <span>💳 Loan Prepay</span>
            <span>Reducing debt faster</span>
          </div>
        </div>
      </div>
    </div>

    <!-- Monthly Checklist -->
    <div class="section glass-card">
      <div class="section-header">
        <h2>✅ This Month's Checklist</h2>
        <div class="header-actions">
          <button @click="resetChecklist" class="btn-small" title="Uncheck all">🔄 Reset</button>
          <button @click="generateSuggestedItems" class="btn-small" title="Add from SIPs & allocations">📋 Auto-fill</button>
        </div>
      </div>
      
      <div class="checklist">
        <!-- Checklist Items -->
        <div v-if="checklistItems.length > 0" class="checklist-items">
          <div 
            v-for="item in checklistItems" 
            :key="item.id" 
            class="checklist-item"
            :class="{ checked: item.is_checked }"
          >
            <button @click="toggleChecklistItem(item)" class="check-btn" :class="{ checked: item.is_checked }">
              <span class="checkbox-icon">{{ item.is_checked ? '✓' : '' }}</span>
            </button>
            <span class="item-name" :class="{ done: item.is_checked }">{{ item.name }}</span>
            <span v-if="item.category !== 'custom'" class="item-tag">{{ item.category }}</span>
            <button @click="deleteChecklistItem(item.id)" class="btn-delete-small">×</button>
          </div>
        </div>

        <!-- Empty State -->
        <div v-else class="checklist-empty">
          <p>No checklist items yet.</p>
          <p class="hint">Click "Auto-fill" to add from your SIPs & allocations, or add custom items below.</p>
        </div>

        <!-- Add New Item -->
        <div class="checklist-add">
          <div v-if="showAddChecklist" class="add-form-inline">
            <input 
              v-model="newChecklistItem" 
              @keyup.enter="addChecklistItem"
              placeholder="New checklist item..." 
              class="input-inline"
              autofocus
            />
            <button @click="addChecklistItem" class="btn-add-inline">Add</button>
            <button @click="showAddChecklist = false; newChecklistItem = ''" class="btn-cancel-inline">×</button>
          </div>
          <button v-else @click="showAddChecklist = true" class="btn-add-item">+ Add Item</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, computed, onMounted, watch, reactive } from 'vue'
import { useFinanceData } from '../composables/useFinanceData'
import { useAuth } from '../composables/useAuth'
import { supabase } from '../lib/supabase'

export default {
  name: 'SurplusAllocation',
  props: {
    valuesHidden: { type: Boolean, default: false }
  },
  setup(props) {
    const { user } = useAuth()
    const { settings, getTotalMonthlyIncome, getTotalMonthlyExpenses, getMonthlySurplus, indianAllocations, convertToEUR, phaseProgress, fetchAllData, liabilities } = useFinanceData()

    const allocations = ref([])
    const showAddForm = ref(false)
    const showSIPEdit = ref(false)
    const editingPhase = ref(1) // Which phase we're viewing/editing allocations for
    const newAlloc = ref({ name: '', percentage: 0, icon: '💰' })
    const newSIP = ref({ name: '', amount: 0, icon: '📈' })
    
    // Fully dynamic fixed investments list
    const fixedInvestments = ref([])

    // Watch indianAllocations and load data (with migration from old format)
    watch(indianAllocations, (newVal) => {
      if (newVal) {
        const investments = []
        
        // Migrate old hardcoded fields if they have values
        if (newVal.ppfas_sourabh) investments.push({ name: 'PPFAS (Sourabh)', amount: newVal.ppfas_sourabh, icon: '📈' })
        if (newVal.ppfas_dhea) investments.push({ name: 'PPFAS (Dhea)', amount: newVal.ppfas_dhea, icon: '📈' })
        if (newVal.rd1) investments.push({ name: 'RD 1', amount: newVal.rd1, icon: '🏦' })
        if (newVal.rd2) investments.push({ name: 'RD 2', amount: newVal.rd2, icon: '🏦' })
        
        // Load custom investments (this is where everything will be stored going forward)
        if (newVal.custom_sips) {
          try {
            const custom = JSON.parse(newVal.custom_sips) || []
            // If we have custom_sips but no old fields, use custom_sips as the source of truth
            if (custom.length > 0 && !newVal.ppfas_sourabh && !newVal.ppfas_dhea && !newVal.rd1 && !newVal.rd2) {
              fixedInvestments.value = custom
              return
            }
            // Otherwise merge (for migration period)
            investments.push(...custom)
          } catch { /* ignore parse errors */ }
        }
        
        fixedInvestments.value = investments
      }
    }, { immediate: true })

    const totalIncome = computed(() => Math.round(getTotalMonthlyIncome.value))
    const totalExpenses = computed(() => Math.round(getTotalMonthlyExpenses.value))
    const surplus = computed(() => Math.round(getMonthlySurplus.value))
    const maskNumber = (num) => props.valuesHidden ? '••••' : num.toLocaleString()
    const currentPhase = computed(() => settings.value?.current_phase || 1)
    
    // Fixed investments totals
    const fixedInvestmentsTotal = computed(() => {
      return fixedInvestments.value.reduce((sum, inv) => sum + (inv.amount || 0), 0)
    })
    const fixedInvestmentsTotalEUR = computed(() => Math.round(convertToEUR(fixedInvestmentsTotal.value, 'INR')))
    
    // Net surplus after fixed investments (what's actually available for phase goals)
    const netSurplus = computed(() => Math.round(surplus.value - fixedInvestmentsTotalEUR.value))

    // Add new investment
    const addInvestment = () => {
      if (!newSIP.value.name || !newSIP.value.amount) return
      fixedInvestments.value.push({ ...newSIP.value })
      newSIP.value = { name: '', amount: 0, icon: '📈' }
    }

    // Remove investment
    const removeInvestment = (index) => {
      fixedInvestments.value.splice(index, 1)
    }

    // Save fixed investments to database
    const saveFixedInvestments = async () => {
      if (!user.value) return
      try {
        // Store everything in custom_sips, clear old fields
        const updateData = {
          ppfas_sourabh: 0,
          ppfas_dhea: 0,
          rd1: 0,
          rd2: 0,
          custom_sips: JSON.stringify(fixedInvestments.value)
        }
        
        // Check if record exists
        const { data: existing } = await supabase
          .from('indian_allocations')
          .select('id')
          .eq('user_id', user.value.id)
          .single()

        if (existing) {
          await supabase
            .from('indian_allocations')
            .update(updateData)
            .eq('user_id', user.value.id)
        } else {
          await supabase
            .from('indian_allocations')
            .insert({ user_id: user.value.id, ...updateData })
        }
        
        await fetchAllData()
        showSIPEdit.value = false
        alert('Saved! ✅')
      } catch (error) {
        console.error('Error saving:', error)
        alert('Failed to save')
      }
    }

    // Phase 1 CC Debt progress
    const ccDebtTarget = computed(() => {
      // Find credit card liability (look for "credit" or "cc" in name, case insensitive)
      const ccDebt = liabilities.value?.find(l => 
        l.name?.toLowerCase().includes('credit') || 
        l.name?.toLowerCase().includes('cc')
      )
      return ccDebt?.amount || 2100 // Default fallback
    })
    
    const ccDebtPaid = computed(() => {
      const phase1 = phaseProgress.value?.find(p => p.phase === 1)
      return phase1?.current || 0
    })
    
    const ccDebtProgress = computed(() => {
      if (ccDebtTarget.value <= 0) return 100
      return Math.min((ccDebtPaid.value / ccDebtTarget.value) * 100, 100)
    })
    
    const ccDebtRemaining = computed(() => Math.max(ccDebtTarget.value - ccDebtPaid.value, 0))
    
    // Editable CC debt paid amount
    const editingCCPaid = ref(false)
    const tempCCPaid = ref(0)
    
    const startEditCCPaid = () => {
      tempCCPaid.value = ccDebtPaid.value
      editingCCPaid.value = true
    }
    
    const saveCCPaid = async () => {
      if (!user.value) return
      try {
        const phase1 = phaseProgress.value?.find(p => p.phase === 1)
        if (phase1) {
          await supabase
            .from('phase_progress')
            .update({ current: tempCCPaid.value })
            .eq('id', phase1.id)
        } else {
          await supabase
            .from('phase_progress')
            .insert({
              user_id: user.value.id,
              phase: 1,
              name: 'Clear Credit Card',
              target: ccDebtTarget.value,
              current: tempCCPaid.value,
              is_complete: tempCCPaid.value >= ccDebtTarget.value
            })
        }
        await fetchAllData()
        editingCCPaid.value = false
      } catch (error) {
        console.error('Error saving CC paid:', error)
      }
    }
    
    const cancelEditCCPaid = () => {
      editingCCPaid.value = false
    }

    // Phase 2 buffer progress
    const bufferCurrent = computed(() => {
      const phase2 = phaseProgress.value?.find(p => p.phase === 2)
      return phase2?.current || 0
    })
    const bufferProgress = computed(() => (bufferCurrent.value / 15000) * 100)

    // Allocation calculations (based on netSurplus - after Indian SIPs)
    const totalAllocated = computed(() => {
      return allocations.value.reduce((sum, a) => {
        if (a.amount) return sum + a.amount
        if (a.percentage) return sum + (netSurplus.value * a.percentage / 100)
        return sum
      }, 0)
    })
    const allocatedPercent = computed(() => netSurplus.value > 0 ? (totalAllocated.value / netSurplus.value) * 100 : 0)

    const getAllocAmount = (alloc) => {
      if (alloc.amount) return Math.round(alloc.amount)
      if (alloc.percentage) return Math.round(netSurplus.value * alloc.percentage / 100)
      return 0
    }

    const getPhaseEmoji = (phase) => ({ 1: '💳', 2: '🛡️', 3: '🚀' }[phase] || '🎯')
    const getPhaseName = (phase) => ({ 1: 'Clear CC Debt', 2: 'Build Buffer', 3: 'Growth Mode' }[phase] || 'Custom')
    const getPhaseDesc = (phase) => ({
      1: 'Focus on paying off high-interest credit card debt (18% APR)',
      2: 'Build €15k emergency buffer while maintaining small investments',
      3: 'Aggressive wealth building with diversified allocation'
    }[phase] || '')

    const fetchAllocations = async () => {
      if (!user.value) return
      const { data } = await supabase
        .from('surplus_allocations')
        .select('*')
        .eq('user_id', user.value.id)
        .eq('phase', editingPhase.value)
        .order('order_index')
      allocations.value = data || []
    }

    const addAllocation = async () => {
      if (!user.value || !newAlloc.value.name) return
      await supabase.from('surplus_allocations').insert({
        user_id: user.value.id,
        phase: editingPhase.value,
        name: newAlloc.value.name,
        percentage: newAlloc.value.percentage || null,
        icon: newAlloc.value.icon,
        order_index: allocations.value.length
      })
      newAlloc.value = { name: '', percentage: 0, icon: '💰' }
      await fetchAllocations()
    }

    const deleteAllocation = async (id) => {
      await supabase.from('surplus_allocations').delete().eq('id', id)
      await fetchAllocations()
    }

    const applyTemplate = async (template) => {
      if (!user.value) return
      const templates = {
        phase1: [{ name: 'Credit Card Debt', percentage: 100, icon: '💳', description: '18% APR - Pay off ASAP' }],
        phase2: [
          { name: 'Cash Buffer', percentage: 80, icon: '💵', description: 'Emergency fund' },
          { name: 'COPX Investment', percentage: 20, icon: '📈', description: 'Keep investing' }
        ],
        phase3: [
          { name: 'COPX Investment', amount: 500, icon: '📈' },
          { name: 'Crash Fund', amount: 400, icon: '🛡️' },
          { name: 'Loan Prepay', amount: 250, icon: '💳' },
          { name: 'Flexible', amount: 363, icon: '💰' }
        ]
      }
      const items = templates[template]
      if (!items) return

      await supabase.from('surplus_allocations').delete().eq('user_id', user.value.id).eq('phase', editingPhase.value)
      for (let i = 0; i < items.length; i++) {
        await supabase.from('surplus_allocations').insert({
          user_id: user.value.id,
          phase: editingPhase.value,
          ...items[i],
          order_index: i
        })
      }
      await fetchAllocations()
      showAddForm.value = false
    }

    // Sync editingPhase to currentPhase when it changes
    watch(currentPhase, (newPhase) => {
      editingPhase.value = newPhase
    }, { immediate: true })
    
    // Fetch allocations when editingPhase changes
    watch(editingPhase, fetchAllocations)

    // ========== CHECKLIST FUNCTIONALITY ==========
    const checklistItems = ref([])
    const showAddChecklist = ref(false)
    const newChecklistItem = ref('')

    const fetchChecklist = async () => {
      if (!user.value) return
      const { data } = await supabase
        .from('checklist_items')
        .select('*')
        .eq('user_id', user.value.id)
        .order('order_index')
      checklistItems.value = data || []
    }

    const toggleChecklistItem = async (item) => {
      await supabase
        .from('checklist_items')
        .update({ is_checked: !item.is_checked })
        .eq('id', item.id)
      item.is_checked = !item.is_checked
    }

    const addChecklistItem = async () => {
      if (!user.value || !newChecklistItem.value.trim()) return
      const { data } = await supabase
        .from('checklist_items')
        .insert({
          user_id: user.value.id,
          name: newChecklistItem.value.trim(),
          is_checked: false,
          category: 'custom',
          order_index: checklistItems.value.length
        })
        .select()
        .single()
      
      if (data) {
        checklistItems.value.push(data)
      }
      newChecklistItem.value = ''
      showAddChecklist.value = false
    }

    const deleteChecklistItem = async (id) => {
      await supabase
        .from('checklist_items')
        .delete()
        .eq('id', id)
      checklistItems.value = checklistItems.value.filter(item => item.id !== id)
    }

    const resetChecklist = async () => {
      if (!user.value) return
      // Uncheck all items
      await supabase
        .from('checklist_items')
        .update({ is_checked: false })
        .eq('user_id', user.value.id)
      checklistItems.value.forEach(item => item.is_checked = false)
    }

    // Auto-generate suggested checklist items from SIPs and allocations
    const generateSuggestedItems = async () => {
      if (!user.value) return
      const suggestions = []
      
      // Add SIP items
      fixedInvestments.value.forEach((inv, i) => {
        suggestions.push({
          user_id: user.value.id,
          name: `${inv.name}: ₹${inv.amount?.toLocaleString() || 0}`,
          is_checked: false,
          category: 'sip',
          order_index: i
        })
      })
      
      // Add allocation items
      allocations.value.forEach((alloc, i) => {
        suggestions.push({
          user_id: user.value.id,
          name: `${alloc.name}: €${getAllocAmount(alloc).toLocaleString()}`,
          is_checked: false,
          category: 'allocation',
          order_index: suggestions.length + i
        })
      })
      
      if (suggestions.length === 0) return
      
      // Insert all suggestions
      const { data } = await supabase
        .from('checklist_items')
        .insert(suggestions)
        .select()
      
      if (data) {
        checklistItems.value.push(...data)
      }
    }

    onMounted(() => {
      fetchAllocations()
      fetchChecklist()
    })

    return {
      totalIncome, totalExpenses, surplus, netSurplus, maskNumber, currentPhase, editingPhase,
      fixedInvestments, fixedInvestmentsTotal, fixedInvestmentsTotalEUR,
      // Phase 1 CC Debt
      ccDebtTarget, ccDebtPaid, ccDebtProgress, ccDebtRemaining,
      editingCCPaid, tempCCPaid, startEditCCPaid, saveCCPaid, cancelEditCCPaid,
      // Phase 2 Buffer
      bufferCurrent, bufferProgress,
      allocations, totalAllocated, allocatedPercent, getAllocAmount,
      showAddForm, newAlloc,
      getPhaseEmoji, getPhaseName, getPhaseDesc,
      addAllocation, deleteAllocation, applyTemplate,
      // Fixed investments editing
      showSIPEdit, newSIP, addInvestment, removeInvestment, saveFixedInvestments,
      // Checklist
      checklistItems, showAddChecklist, newChecklistItem,
      toggleChecklistItem, addChecklistItem, deleteChecklistItem, resetChecklist, generateSuggestedItems
    }
  }
}
</script>

<style scoped>
.surplus-tab {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}

/* Overview Banner - extends global .page-banner */
.overview-banner {
  text-align: left;
}

.overview-row {
  display: flex;
  justify-content: space-between;
  gap: 1rem;
  flex-wrap: wrap;
}

.overview-breakdown {
  margin-top: 1rem;
  padding-top: 1rem;
  border-top: 1px solid var(--border);
}

.breakdown-line {
  display: flex;
  justify-content: space-between;
  padding: 0.35rem 0;
  font-size: 0.9rem;
  color: var(--text-secondary);
}

.breakdown-line.deduction {
  color: var(--warning);
}

.breakdown-line.net {
  font-weight: 600;
  padding-top: 0.5rem;
  margin-top: 0.25rem;
  border-top: 1px dashed var(--border);
}

.breakdown-line.net .surplus {
  color: var(--primary);
  font-size: 1.1rem;
}

.overview-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  flex: 1;
  min-width: 100px;
}

.overview-item .banner-label {
  margin-bottom: 0.25rem;
}

.overview-value {
  font-size: 1.5rem;
  font-weight: 700;
}

.overview-value.income { color: var(--success); }
.overview-value.expenses { color: var(--danger); }
.overview-value.muted { color: var(--text-secondary); }

/* Sections */
.section {
  padding: 1.25rem;
}

.section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 0.5rem;
}

.section-header h2 {
  font-size: 1.1rem;
  font-weight: 600;
}

.section-badge {
  font-size: 0.7rem;
  padding: 0.25rem 0.5rem;
  border-radius: 4px;
  font-weight: 600;
}

.section-badge.always {
  background: rgba(16, 185, 129, 0.2);
  color: var(--success);
}

.section-desc {
  font-size: 0.85rem;
  color: var(--text-muted);
  margin-bottom: 1rem;
}

.btn-edit {
  padding: 0.35rem 0.75rem;
  font-size: 0.8rem;
  background: var(--bg-glass);
  border: 1px solid var(--border);
  border-radius: 6px;
  color: var(--text-secondary);
  cursor: pointer;
}

.btn-edit:hover {
  border-color: var(--primary);
}

.phase-selector {
  padding: 0.35rem 0.5rem;
  font-size: 0.8rem;
  background: var(--bg-glass);
  border: 1px solid var(--border);
  border-radius: 6px;
  color: var(--text);
  cursor: pointer;
}

.phase-selector:focus {
  outline: none;
  border-color: var(--primary);
}

.section-note {
  font-size: 0.8rem;
  color: var(--warning);
  background: rgba(245, 158, 11, 0.1);
  padding: 0.5rem 0.75rem;
  border-radius: 6px;
  margin-bottom: 1rem;
}

/* Allocation List */
.allocation-list {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.allocation-row {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 0.75rem;
  background: var(--bg-glass);
  border-radius: 8px;
}

.allocation-row.editable {
  border-left: 3px solid var(--primary);
}

.alloc-icon {
  font-size: 1.25rem;
}

.alloc-details {
  flex: 1;
  display: flex;
  flex-direction: column;
}

.alloc-name {
  font-weight: 500;
  flex: 1;
}

.alloc-desc {
  font-size: 0.75rem;
  color: var(--text-muted);
}

.alloc-amount {
  font-weight: 600;
  text-align: right;
}

.eur-equiv {
  font-size: 0.8rem;
  color: var(--text-muted);
  font-weight: 400;
}

.allocation-total {
  display: flex;
  justify-content: space-between;
  padding: 0.75rem;
  background: var(--bg-elevated);
  border-radius: 8px;
  font-weight: 600;
  margin-top: 0.5rem;
}

.allocation-total .warning {
  color: var(--warning);
}

.btn-remove {
  width: 24px;
  height: 24px;
  border: none;
  background: rgba(239, 68, 68, 0.2);
  color: var(--danger);
  border-radius: 4px;
  cursor: pointer;
  font-size: 0.8rem;
}

.empty-message {
  padding: 1.5rem;
  text-align: center;
  color: var(--text-muted);
  background: var(--bg-glass);
  border-radius: 8px;
}

/* Add Form */
.add-form {
  display: flex;
  gap: 0.5rem;
  align-items: center;
  flex-wrap: wrap;
  padding: 0.75rem;
  background: var(--bg-glass);
  border: 1px dashed var(--border);
  border-radius: 8px;
}

.input-icon {
  width: 50px;
  padding: 0.5rem;
  background: var(--bg-elevated);
  border: 1px solid var(--border);
  border-radius: 6px;
  font-size: 1rem;
}

.input-name {
  flex: 1;
  min-width: 120px;
  padding: 0.5rem;
  background: var(--bg-elevated);
  border: 1px solid var(--border);
  border-radius: 6px;
  color: var(--text);
}

.input-pct {
  width: 60px;
  padding: 0.5rem;
  background: var(--bg-elevated);
  border: 1px solid var(--border);
  border-radius: 6px;
  color: var(--text);
  text-align: right;
}

.pct-label {
  color: var(--text-muted);
}

.btn-add {
  padding: 0.5rem 1rem;
  background: var(--success);
  color: white;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  font-weight: 500;
}

/* Templates */
.templates {
  padding: 0.75rem;
  background: var(--bg-glass);
  border-radius: 8px;
}

.templates-label {
  font-size: 0.8rem;
  color: var(--text-muted);
  margin-bottom: 0.5rem;
}

.template-btns {
  display: flex;
  gap: 0.5rem;
  flex-wrap: wrap;
}

.template-btns button {
  padding: 0.4rem 0.75rem;
  font-size: 0.8rem;
  background: var(--bg-elevated);
  border: 1px solid var(--border);
  border-radius: 6px;
  color: var(--text-secondary);
  cursor: pointer;
}

.template-btns button:hover {
  border-color: var(--primary);
  color: var(--primary);
}

/* Goal Card */
.goal-card {
  background: var(--bg-glass);
  border-radius: 10px;
  padding: 1rem;
}

.goal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 0.75rem;
}

.goal-name {
  font-weight: 600;
}

.goal-target {
  font-size: 0.8rem;
  color: var(--text-muted);
}

.goal-progress-bar {
  margin-bottom: 0.75rem;
}

.progress-track {
  height: 10px;
  background: var(--border);
  border-radius: 5px;
  overflow: hidden;
}

.progress-fill {
  height: 100%;
  background: linear-gradient(90deg, var(--primary), var(--success));
  border-radius: 5px;
  transition: width 0.3s;
}

.progress-labels {
  display: flex;
  justify-content: space-between;
  font-size: 0.8rem;
  color: var(--text-muted);
  margin-top: 0.25rem;
}

.goal-projection p {
  font-size: 0.9rem;
  color: var(--text-secondary);
  margin: 0.25rem 0;
}

.projection-result {
  color: var(--primary);
  font-weight: 500;
}

.projection-result.success {
  color: var(--success);
}

/* Phase 1 CC Debt Paid Section */
.goal-paid-section {
  margin: 1rem 0;
  padding: 0.75rem;
  background: var(--bg-glass);
  border-radius: 8px;
}

.paid-display {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  flex-wrap: wrap;
}

.paid-label {
  font-size: 0.9rem;
  color: var(--text-secondary);
}

.paid-value {
  font-size: 1.1rem;
  font-weight: 600;
  color: var(--success);
}

.btn-edit-small {
  padding: 0.35rem 0.75rem;
  background: var(--bg-elevated);
  border: 1px solid var(--border);
  border-radius: 6px;
  color: var(--text-secondary);
  font-size: 0.8rem;
  cursor: pointer;
}

.btn-edit-small:hover {
  border-color: var(--primary);
}

.paid-edit {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  flex-wrap: wrap;
}

.paid-edit label {
  font-size: 0.9rem;
  color: var(--text-secondary);
}

.input-paid {
  width: 120px;
  padding: 0.5rem;
  background: var(--bg-elevated);
  border: 1px solid var(--border);
  border-radius: 6px;
  color: var(--text);
  font-size: 1rem;
}

.input-paid:focus {
  border-color: var(--primary);
  outline: none;
}

.btn-save-small {
  padding: 0.5rem 1rem;
  background: var(--success);
  border: none;
  border-radius: 6px;
  color: white;
  font-weight: 500;
  cursor: pointer;
}

.btn-cancel-small {
  padding: 0.5rem 0.75rem;
  background: transparent;
  border: 1px solid var(--border);
  border-radius: 6px;
  color: var(--text-muted);
  cursor: pointer;
}

.goal-breakdown {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.breakdown-item {
  display: flex;
  justify-content: space-between;
  font-size: 0.9rem;
  padding: 0.5rem;
  background: var(--bg-elevated);
  border-radius: 6px;
}

.breakdown-item span:last-child {
  color: var(--text-muted);
}

/* Checklist */
.checklist {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

.checklist-items {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.checklist-item {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 0.75rem;
  background: var(--bg-glass);
  border-radius: 8px;
  transition: all 0.2s;
}

.checklist-item:hover {
  background: var(--bg-elevated);
}

.checklist-item.checked {
  opacity: 0.7;
}

.check-btn {
  width: 24px;
  height: 24px;
  min-width: 24px;
  background: var(--bg-elevated);
  border: 2px solid var(--border);
  border-radius: 6px;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s;
}

.check-btn:hover {
  border-color: var(--primary);
}

.check-btn.checked {
  background: var(--primary);
  border-color: var(--primary);
}

.checkbox-icon {
  color: white;
  font-size: 1rem;
  font-weight: 700;
  line-height: 1;
}

.item-name {
  flex: 1;
  font-size: 0.95rem;
}

.item-name.done {
  text-decoration: line-through;
  color: var(--text-muted);
}

.item-tag {
  font-size: 0.7rem;
  padding: 0.2rem 0.5rem;
  background: var(--bg-elevated);
  border-radius: 4px;
  color: var(--text-muted);
  text-transform: uppercase;
}

.btn-delete-small {
  background: none;
  border: none;
  color: var(--text-muted);
  font-size: 1.25rem;
  cursor: pointer;
  padding: 0 0.25rem;
  opacity: 0;
  transition: opacity 0.2s;
}

.checklist-item:hover .btn-delete-small {
  opacity: 1;
}

.btn-delete-small:hover {
  color: var(--danger);
}

.checklist-empty {
  text-align: center;
  padding: 2rem 1rem;
  color: var(--text-muted);
}

.checklist-empty p {
  margin: 0.5rem 0;
}

.checklist-empty .hint {
  font-size: 0.85rem;
}

.checklist-add {
  margin-top: 0.5rem;
}

.btn-add-item {
  width: 100%;
  padding: 0.75rem;
  background: var(--bg-glass);
  border: 1px dashed var(--border);
  border-radius: 8px;
  color: var(--text-secondary);
  font-size: 0.9rem;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-add-item:hover {
  border-color: var(--primary);
  color: var(--primary);
}

.add-form-inline {
  display: flex;
  gap: 0.5rem;
}

.input-inline {
  flex: 1;
  padding: 0.75rem;
  background: var(--bg-elevated);
  border: 1px solid var(--border);
  border-radius: 8px;
  color: var(--text);
  font-size: 0.9rem;
}

.input-inline:focus {
  border-color: var(--primary);
  outline: none;
}

.btn-add-inline {
  padding: 0.75rem 1rem;
  background: var(--primary);
  border: none;
  border-radius: 8px;
  color: white;
  font-weight: 500;
  cursor: pointer;
}

.btn-cancel-inline {
  padding: 0.75rem;
  background: transparent;
  border: 1px solid var(--border);
  border-radius: 8px;
  color: var(--text-muted);
  cursor: pointer;
}

.btn-small {
  padding: 0.4rem 0.75rem;
  background: var(--bg-elevated);
  border: 1px solid var(--border);
  border-radius: 6px;
  color: var(--text-secondary);
  font-size: 0.8rem;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-small:hover {
  border-color: var(--primary);
  color: var(--text);
}

/* SIP Editing */
.header-actions {
  display: flex;
  align-items: center;
  gap: 0.75rem;
}

.sip-input-group {
  display: flex;
  align-items: center;
  gap: 0.25rem;
}

.currency-symbol {
  color: var(--text-muted);
  font-weight: 600;
}

.sip-input {
  width: 100px;
  padding: 0.5rem;
  background: var(--bg-elevated);
  border: 1px solid var(--border);
  border-radius: 6px;
  color: var(--text);
  text-align: right;
  font-weight: 500;
}

.sip-input:focus {
  outline: none;
  border-color: var(--primary);
}

.input-icon-small {
  width: 45px;
  padding: 0.4rem;
  background: var(--bg-elevated);
  border: 1px solid var(--border);
  border-radius: 6px;
  font-size: 1rem;
}

.input-name-edit {
  flex: 1;
  min-width: 100px;
  padding: 0.5rem;
  background: var(--bg-elevated);
  border: 1px solid var(--border);
  border-radius: 6px;
  color: var(--text);
  font-size: 0.9rem;
}

.input-name-edit:focus {
  outline: none;
  border-color: var(--primary);
}

.add-sip-form {
  display: flex;
  gap: 0.5rem;
  align-items: center;
  flex-wrap: wrap;
  padding: 0.75rem;
  background: var(--bg-glass);
  border: 1px dashed var(--border);
  border-radius: 8px;
  margin-top: 0.5rem;
}

.custom-sip {
  border-left-color: var(--warning);
}

.sip-actions {
  display: flex;
  justify-content: center;
  padding: 1rem 0;
}

/* Mobile */
@media (max-width: 768px) {
  .overview-row {
    flex-direction: column;
    gap: 0.75rem;
  }
  
  .overview-item {
    flex-direction: row;
    justify-content: space-between;
  }
  
  .allocation-row {
    flex-wrap: wrap;
  }
  
  .alloc-amount {
    width: 100%;
    text-align: left;
    margin-top: 0.25rem;
  }

  .header-actions {
    flex-wrap: wrap;
  }

  .add-sip-form {
    flex-direction: column;
    align-items: stretch;
  }

  .add-sip-form .input-name,
  .add-sip-form .sip-input-group {
    width: 100%;
  }
}
</style>
