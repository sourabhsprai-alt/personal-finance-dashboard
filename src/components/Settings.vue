<template>
  <div class="settings">
    <!-- Phase Management -->
    <div class="settings-section">
      <h2>🎯 Phase Management</h2>
      
      <div class="current-phase-display">
        <span class="label">Current Phase:</span>
        <select v-model="selectedPhase" @change="handlePhaseSwitch" class="phase-select">
          <option :value="1">Phase 1: Clear Credit Card</option>
          <option :value="2">Phase 2: Build €15k Buffer</option>
          <option :value="3">Phase 3: Aggressive Growth</option>
        </select>
      </div>

      <div class="roadmap-toggle">
        <button @click="showRoadmap = !showRoadmap" class="btn-toggle">
          {{ showRoadmap ? '▼ Hide' : '▶ Show' }} Phase Roadmap
        </button>
      </div>

      <!-- Phase Roadmap -->
      <div v-if="showRoadmap" class="phase-roadmap">
        <div 
          v-for="phase in phases" 
          :key="phase.phase"
          class="roadmap-item"
          :class="{ 
            'active': phase.phase === selectedPhase,
            'complete': phase.is_complete,
            'future': phase.phase > selectedPhase && !phase.is_complete
          }"
        >
          <div class="roadmap-marker">
            <span v-if="phase.is_complete">✅</span>
            <span v-else-if="phase.phase === selectedPhase">🔵</span>
            <span v-else>⚪</span>
          </div>
          <div class="roadmap-content">
            <h4>Phase {{ phase.phase }}: {{ phase.name }}</h4>
            <div class="roadmap-details" v-if="phase.target">
              <div class="progress-info">
                <span>Progress: €{{ maskNumber(phase.current) || 0 }} / €{{ maskNumber(phase.target) }}</span>
                <span class="percentage">({{ ((phase.current || 0) / phase.target * 100).toFixed(0) }}%)</span>
              </div>
              <div class="progress-bar-small">
                <div 
                  class="progress-fill-small" 
                  :style="{ width: `${Math.min((phase.current || 0) / phase.target * 100, 100)}%` }"
                ></div>
              </div>
            </div>
            <p class="phase-description">{{ getPhaseDescription(phase.phase) }}</p>
          </div>
        </div>

        <!-- Phase 3 (always shown in roadmap) -->
        <div 
          class="roadmap-item"
          :class="{ 
            'active': selectedPhase === 3,
            'future': selectedPhase < 3
          }"
          v-if="!phases.find(p => p.phase === 3)"
        >
          <div class="roadmap-marker">
            <span v-if="selectedPhase === 3">🔵</span>
            <span v-else>⚪</span>
          </div>
          <div class="roadmap-content">
            <h4>Phase 3: Aggressive Growth</h4>
            <p class="phase-description">{{ getPhaseDescription(3) }}</p>
          </div>
        </div>
      </div>

      <!-- Phase Progress Editor -->
      <div class="phase-editor" v-if="currentPhaseData">
        <h3>Update Phase {{ selectedPhase }} Progress</h3>
        <div class="editor-row">
          <label>Current Progress (€):</label>
          <input 
            type="number" 
            v-model.number="editProgress"
            class="progress-input"
          />
          <button @click="updateProgress" class="btn-primary btn-small">Update</button>
        </div>
        <div class="editor-row" v-if="currentPhaseData.target">
          <label>Target: €{{ maskNumber(currentPhaseData.target) }}</label>
          <button 
            @click="markComplete" 
            class="btn-success btn-small"
            :disabled="currentPhaseData.is_complete"
          >
            {{ currentPhaseData.is_complete ? '✅ Complete' : 'Mark Complete' }}
          </button>
        </div>
      </div>
    </div>

    <!-- Exchange Rates -->
    <div class="settings-section" v-if="settings">
      <h2>💱 Exchange Rates</h2>
      <div class="settings-grid">
        <div class="setting-item">
          <label>EUR to INR</label>
          <input 
            type="number" 
            step="0.01"
            v-model.number="localSettings.eur_to_inr"
          />
        </div>
        <div class="setting-item">
          <label>EUR to USD</label>
          <input 
            type="number" 
            step="0.01"
            v-model.number="localSettings.eur_to_usd"
          />
        </div>
        <div class="setting-item">
          <label>USD to EUR</label>
          <input 
            type="number" 
            step="0.01"
            v-model.number="localSettings.usd_to_eur"
          />
        </div>
      </div>
      <button @click="fetchLiveRates" class="btn-secondary">Fetch Live Rates</button>
    </div>

    <!-- Target Metrics -->
    <div class="settings-section" v-if="settings">
      <h2>📊 Target Metrics</h2>
      <div class="settings-grid">
        <div class="setting-item">
          <label>Crypto Exposure Target (%)</label>
          <input 
            type="number" 
            v-model.number="localSettings.target_crypto_exposure"
          />
          <span class="setting-note">Current: {{ getCryptoExposure.toFixed(1) }}%</span>
        </div>
        <div class="setting-item">
          <label>Illiquid Assets Target (%)</label>
          <input 
            type="number" 
            v-model.number="localSettings.target_illiquid_assets"
          />
          <span class="setting-note">Current: {{ getIlliquidExposure.toFixed(1) }}%</span>
        </div>
        <div class="setting-item">
          <label>Debt-to-Net-Worth Target (%)</label>
          <input 
            type="number" 
            v-model.number="localSettings.target_debt_to_networth"
          />
          <span class="setting-note">Current: {{ getDebtToNetWorth.toFixed(1) }}%</span>
        </div>
        <div class="setting-item">
          <label>Emergency Buffer Target (EUR)</label>
          <input 
            type="number" 
            v-model.number="localSettings.target_emergency_buffer"
          />
        </div>
      </div>
    </div>

    <!-- Save All Button -->
    <div class="save-section">
      <button @click="saveSettings" class="btn-primary btn-save-all">💾 Save All Settings</button>
    </div>
  </div>
</template>

<script>
import { ref, watch, computed } from 'vue'
import { useFinanceData } from '../composables/useFinanceData'
import { supabase } from '../lib/supabase'
import { useAuth } from '../composables/useAuth'

export default {
  name: 'Settings',
  props: {
    valuesHidden: { type: Boolean, default: false }
  },
  setup(props) {
    const { user } = useAuth()
    const {
      settings,
      phaseProgress,
      fetchAllData,
      getCryptoExposure,
      getIlliquidExposure,
      getDebtToNetWorth
    } = useFinanceData()

    const localSettings = ref({})
    const maskNumber = (num) => props.valuesHidden ? '••••' : num?.toLocaleString()
    const showRoadmap = ref(true)
    const selectedPhase = ref(1)
    const editProgress = ref(0)

    const phases = computed(() => phaseProgress.value || [])

    const currentPhaseData = computed(() => {
      return phases.value.find(p => p.phase === selectedPhase.value)
    })

    watch(settings, (newSettings) => {
      if (newSettings) {
        localSettings.value = { ...newSettings }
        selectedPhase.value = newSettings.current_phase || 1
      }
    }, { immediate: true })

    watch(currentPhaseData, (newData) => {
      if (newData) {
        editProgress.value = newData.current || 0
      }
    }, { immediate: true })

    const getPhaseDescription = (phase) => {
      const descriptions = {
        1: 'Clear high-interest credit card debt (18% APR) as priority',
        2: 'Build emergency buffer: €1,400/month to buffer + €150 to COPX',
        3: 'Aggressive growth: €500 COPX + €400 crash fund + €250 loan prepay + €363 flexible'
      }
      return descriptions[phase] || ''
    }

    const handlePhaseSwitch = async () => {
      if (!user.value) return
      try {
        await supabase
          .from('settings')
          .update({ current_phase: selectedPhase.value })
          .eq('user_id', user.value.id)
        await fetchAllData()
      } catch (error) {
        console.error('Error switching phase:', error)
      }
    }

    const updateProgress = async () => {
      if (!user.value || !currentPhaseData.value) return
      try {
        await supabase
          .from('phase_progress')
          .update({ current: editProgress.value })
          .eq('user_id', user.value.id)
          .eq('phase', selectedPhase.value)
        await fetchAllData()
        alert('Progress updated! ✅')
      } catch (error) {
        console.error('Error updating progress:', error)
      }
    }

    const markComplete = async () => {
      if (!user.value || !currentPhaseData.value) return
      try {
        // Mark current phase complete
        await supabase
          .from('phase_progress')
          .update({ 
            current: currentPhaseData.value.target,
            is_complete: true 
          })
          .eq('user_id', user.value.id)
          .eq('phase', selectedPhase.value)
        
        // Move to next phase
        const nextPhase = selectedPhase.value + 1
        if (nextPhase <= 3) {
          await supabase
            .from('settings')
            .update({ current_phase: nextPhase })
            .eq('user_id', user.value.id)
          selectedPhase.value = nextPhase
        }
        
        await fetchAllData()
        alert('Phase marked complete! 🎉')
      } catch (error) {
        console.error('Error marking complete:', error)
      }
    }

    const saveSettings = async () => {
      if (!user.value) return
      try {
        await supabase
          .from('settings')
          .update(localSettings.value)
          .eq('user_id', user.value.id)
        await fetchAllData()
        alert('Settings saved! ✅')
      } catch (error) {
        console.error('Error saving settings:', error)
      }
    }

    const fetchLiveRates = async () => {
      try {
        const response = await fetch('https://api.frankfurter.app/latest?from=EUR&to=INR,USD')
        const data = await response.json()
        
        if (data.rates) {
          localSettings.value.eur_to_inr = data.rates.INR
          localSettings.value.eur_to_usd = data.rates.USD
          localSettings.value.usd_to_eur = 1 / data.rates.USD
          await saveSettings()
          alert('Rates updated! ✅')
        }
      } catch (error) {
        console.error('Failed to fetch rates:', error)
        alert('Failed to fetch live rates.')
      }
    }

    return {
      settings,
      localSettings,
      maskNumber,
      phases,
      showRoadmap,
      selectedPhase,
      editProgress,
      currentPhaseData,
      getCryptoExposure,
      getIlliquidExposure,
      getDebtToNetWorth,
      getPhaseDescription,
      handlePhaseSwitch,
      updateProgress,
      markComplete,
      saveSettings,
      fetchLiveRates
    }
  }
}
</script>

<style scoped>
.settings {
  display: flex;
  flex-direction: column;
  gap: 2rem;
}

.settings-section {
  background: var(--bg-light);
  border-radius: 1rem;
  padding: 1.5rem;
  border: 2px solid var(--border);
}

h2 {
  font-size: 1.5rem;
  margin-bottom: 1.5rem;
}

h3 {
  font-size: 1.2rem;
  margin-bottom: 1rem;
  color: var(--text-muted);
}

/* Phase Management */
.current-phase-display {
  display: flex;
  align-items: center;
  gap: 1rem;
  margin-bottom: 1rem;
}

.current-phase-display .label {
  font-weight: 600;
  color: var(--text-muted);
}

.phase-select {
  padding: 0.75rem 1rem;
  background: var(--bg);
  border: 2px solid var(--border);
  border-radius: 0.5rem;
  color: var(--text);
  font-size: 1rem;
  font-weight: 600;
  cursor: pointer;
  min-width: 250px;
}

.phase-select:focus {
  outline: none;
  border-color: var(--primary);
}

.roadmap-toggle {
  margin-bottom: 1rem;
}

.btn-toggle {
  padding: 0.5rem 1rem;
  background: var(--bg);
  border: 1px solid var(--border);
  border-radius: 0.5rem;
  color: var(--text-muted);
  cursor: pointer;
  font-size: 0.9rem;
}

.btn-toggle:hover {
  border-color: var(--primary);
}

/* Phase Roadmap */
.phase-roadmap {
  margin-bottom: 1.5rem;
  padding: 1rem;
  background: var(--bg);
  border-radius: 0.75rem;
}

.roadmap-item {
  display: flex;
  gap: 1rem;
  padding: 1rem;
  margin-bottom: 0.5rem;
  border-radius: 0.5rem;
  border-left: 4px solid var(--border);
  transition: all 0.2s;
}

.roadmap-item.active {
  background: rgba(59, 130, 246, 0.1);
  border-left-color: var(--primary);
}

.roadmap-item.complete {
  border-left-color: var(--success);
  opacity: 0.8;
}

.roadmap-item.future {
  opacity: 0.5;
}

.roadmap-marker {
  font-size: 1.5rem;
  width: 40px;
  text-align: center;
}

.roadmap-content {
  flex: 1;
}

.roadmap-content h4 {
  margin-bottom: 0.5rem;
  color: var(--text);
}

.roadmap-details {
  margin-bottom: 0.5rem;
}

.progress-info {
  display: flex;
  gap: 0.5rem;
  font-size: 0.9rem;
  color: var(--text-muted);
  margin-bottom: 0.5rem;
}

.percentage {
  color: var(--primary);
  font-weight: 600;
}

.progress-bar-small {
  height: 6px;
  background: var(--border);
  border-radius: 3px;
  overflow: hidden;
}

.progress-fill-small {
  height: 100%;
  background: var(--primary);
  border-radius: 3px;
  transition: width 0.3s;
}

.phase-description {
  font-size: 0.85rem;
  color: var(--text-muted);
  font-style: italic;
}

/* Phase Editor */
.phase-editor {
  padding: 1rem;
  background: var(--bg);
  border-radius: 0.75rem;
  margin-top: 1rem;
}

.editor-row {
  display: flex;
  align-items: center;
  gap: 1rem;
  margin-bottom: 1rem;
}

.editor-row label {
  color: var(--text-muted);
  min-width: 150px;
}

.progress-input {
  padding: 0.5rem;
  background: var(--bg-light);
  border: 2px solid var(--border);
  border-radius: 0.5rem;
  color: var(--text);
  font-size: 1rem;
  font-weight: 600;
  width: 120px;
}

.progress-input:focus {
  outline: none;
  border-color: var(--primary);
}

/* Settings Grid */
.settings-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 1.5rem;
  margin-bottom: 1rem;
}

.setting-item {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.setting-item label {
  font-weight: 600;
  color: var(--text-muted);
  font-size: 0.9rem;
}

.setting-item input {
  padding: 0.75rem;
  background: var(--bg);
  border: 2px solid var(--border);
  border-radius: 0.5rem;
  color: var(--text);
  font-size: 1rem;
  font-weight: 600;
}

.setting-item input:focus {
  outline: none;
  border-color: var(--primary);
}

.setting-note {
  font-size: 0.85rem;
  color: var(--text-muted);
  font-style: italic;
}

/* Buttons */
.btn-primary,
.btn-secondary,
.btn-success {
  padding: 0.75rem 1.5rem;
  border: none;
  border-radius: 0.5rem;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
  font-size: 1rem;
}

.btn-small {
  padding: 0.5rem 1rem;
  font-size: 0.9rem;
}

.btn-primary {
  background: var(--primary);
  color: white;
}

.btn-primary:hover {
  background: #2563eb;
  transform: translateY(-2px);
}

.btn-secondary {
  background: var(--bg);
  color: var(--text);
  border: 2px solid var(--border);
}

.btn-secondary:hover {
  border-color: var(--primary);
}

.btn-success {
  background: var(--success);
  color: white;
}

.btn-success:hover:not(:disabled) {
  background: #059669;
}

.btn-success:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

/* Save Section */
.save-section {
  display: flex;
  justify-content: center;
  padding: 1rem;
}

.btn-save-all {
  font-size: 1.1rem;
  padding: 1rem 2.5rem;
  box-shadow: 0 4px 12px rgba(59, 130, 246, 0.3);
}

.btn-save-all:hover {
  box-shadow: 0 6px 16px rgba(59, 130, 246, 0.4);
}
</style>
