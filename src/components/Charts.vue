<template>
  <div class="charts">
    <h2>📈 Portfolio Charts</h2>

    <div v-if="loading" class="loading">Loading...</div>

    <div v-else class="charts-container">
      <!-- Net Worth Over Time -->
      <div class="chart-card">
        <h3>💎 Net Worth Over Time</h3>
        <div class="chart-wrapper" v-if="chartData">
          <Line :data="chartData" :options="chartOptions" />
        </div>
        <div v-else class="no-data">
          No snapshot data available. Create snapshots to see historical trends.
        </div>
      </div>

      <!-- Exposure Trends -->
      <div class="chart-card">
        <h3>📊 Exposure Trends</h3>
        <div class="chart-wrapper" v-if="exposureChartData">
          <Line :data="exposureChartData" :options="exposureChartOptions" />
        </div>
        <div v-else class="no-data">
          No exposure data available.
        </div>
      </div>

      <!-- Quick Stats -->
      <div class="stats-grid">
        <div class="stat-card">
          <span class="stat-label">Total Snapshots</span>
          <span class="stat-value">{{ snapshots.length }}</span>
        </div>
        <div class="stat-card" v-if="netWorthChange">
          <span class="stat-label">Net Worth Change (90d)</span>
          <span class="stat-value" :class="netWorthChangeClass">
            {{ netWorthChange > 0 ? '+' : '' }}{{ formatCurrency(netWorthChange, 'EUR') }}
            ({{ netWorthChangePercent > 0 ? '+' : '' }}{{ netWorthChangePercent.toFixed(1) }}%)
          </span>
        </div>
        <div class="stat-card" v-if="latestSnapshot">
          <span class="stat-label">Latest Snapshot</span>
          <span class="stat-value">{{ formatDate(latestSnapshot.snapshot_date) }}</span>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { computed } from 'vue'
import { Line } from 'vue-chartjs'
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  Title,
  Tooltip,
  Legend,
  Filler
} from 'chart.js'
import { useFinanceData } from '../composables/useFinanceData'

ChartJS.register(
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  Title,
  Tooltip,
  Legend,
  Filler
)

export default {
  name: 'Charts',
  components: {
    Line
  },
  props: {
    valuesHidden: { type: Boolean, default: false }
  },
  setup(props) {
    const {
      snapshots,
      loading,
      formatCurrency
    } = useFinanceData()

    const latestSnapshot = computed(() => {
      if (snapshots.value.length === 0) return null
      return snapshots.value[snapshots.value.length - 1]
    })

    const netWorthChange = computed(() => {
      if (snapshots.value.length < 2) return null
      const first = snapshots.value[0].net_worth
      const last = snapshots.value[snapshots.value.length - 1].net_worth
      return last - first
    })

    const netWorthChangePercent = computed(() => {
      if (snapshots.value.length < 2) return 0
      const first = snapshots.value[0].net_worth
      const last = snapshots.value[snapshots.value.length - 1].net_worth
      return ((last - first) / first) * 100
    })

    const netWorthChangeClass = computed(() => {
      if (!netWorthChange.value) return ''
      return netWorthChange.value >= 0 ? 'positive' : 'negative'
    })

    const chartData = computed(() => {
      if (snapshots.value.length === 0) return null

      const labels = snapshots.value.map(s => formatDate(s.snapshot_date))
      const netWorthData = snapshots.value.map(s => s.net_worth)
      const investmentData = snapshots.value.map(s => s.total_investments)
      const liabilityData = snapshots.value.map(s => s.total_liabilities)

      return {
        labels,
        datasets: [
          {
            label: 'Net Worth',
            data: netWorthData,
            borderColor: '#10b981',
            backgroundColor: 'rgba(16, 185, 129, 0.1)',
            tension: 0.4,
            fill: true,
            pointRadius: 4,
            pointHoverRadius: 6
          },
          {
            label: 'Total Investments',
            data: investmentData,
            borderColor: '#8b5cf6',
            backgroundColor: 'rgba(139, 92, 246, 0.1)',
            tension: 0.4,
            fill: false,
            pointRadius: 3,
            pointHoverRadius: 5
          },
          {
            label: 'Total Liabilities',
            data: liabilityData,
            borderColor: '#ef4444',
            backgroundColor: 'rgba(239, 68, 68, 0.1)',
            tension: 0.4,
            fill: false,
            pointRadius: 3,
            pointHoverRadius: 5
          }
        ]
      }
    })

    const exposureChartData = computed(() => {
      if (snapshots.value.length === 0) return null

      const labels = snapshots.value.map(s => formatDate(s.snapshot_date))
      const cryptoData = snapshots.value.map(s => s.crypto_exposure_pct || 0)
      const illiquidData = snapshots.value.map(s => s.illiquid_exposure_pct || 0)
      const debtData = snapshots.value.map(s => s.debt_to_networth_pct || 0)

      return {
        labels,
        datasets: [
          {
            label: 'Crypto Exposure %',
            data: cryptoData,
            borderColor: '#f59e0b',
            backgroundColor: 'rgba(245, 158, 11, 0.1)',
            tension: 0.4,
            fill: false
          },
          {
            label: 'Illiquid Assets %',
            data: illiquidData,
            borderColor: '#3b82f6',
            backgroundColor: 'rgba(59, 130, 246, 0.1)',
            tension: 0.4,
            fill: false
          },
          {
            label: 'Debt-to-Net-Worth %',
            data: debtData,
            borderColor: '#ef4444',
            backgroundColor: 'rgba(239, 68, 68, 0.1)',
            tension: 0.4,
            fill: false
          }
        ]
      }
    })

    const chartOptions = {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        legend: {
          display: true,
          position: 'top',
          labels: {
            color: '#9ca3af',
            font: {
              size: 12
            }
          }
        },
        tooltip: {
          backgroundColor: 'rgba(17, 24, 39, 0.95)',
          titleColor: '#f3f4f6',
          bodyColor: '#f3f4f6',
          borderColor: '#4b5563',
          borderWidth: 1,
          padding: 12,
          displayColors: true,
          callbacks: {
            label: function(context) {
              let label = context.dataset.label || ''
              if (label) {
                label += ': '
              }
              label += '€' + context.parsed.y.toLocaleString('en-DE', { maximumFractionDigits: 0 })
              return label
            }
          }
        }
      },
      scales: {
        y: {
          beginAtZero: false,
          ticks: {
            color: '#9ca3af',
            callback: function(value) {
              return '€' + value.toLocaleString('en-DE', { maximumFractionDigits: 0 })
            }
          },
          grid: {
            color: 'rgba(75, 85, 99, 0.3)'
          }
        },
        x: {
          ticks: {
            color: '#9ca3af',
            maxRotation: 45,
            minRotation: 45
          },
          grid: {
            color: 'rgba(75, 85, 99, 0.3)'
          }
        }
      }
    }

    const exposureChartOptions = {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        legend: {
          display: true,
          position: 'top',
          labels: {
            color: '#9ca3af',
            font: {
              size: 12
            }
          }
        },
        tooltip: {
          backgroundColor: 'rgba(17, 24, 39, 0.95)',
          titleColor: '#f3f4f6',
          bodyColor: '#f3f4f6',
          borderColor: '#4b5563',
          borderWidth: 1,
          padding: 12,
          displayColors: true,
          callbacks: {
            label: function(context) {
              let label = context.dataset.label || ''
              if (label) {
                label += ': '
              }
              label += context.parsed.y.toFixed(1) + '%'
              return label
            }
          }
        }
      },
      scales: {
        y: {
          beginAtZero: true,
          ticks: {
            color: '#9ca3af',
            callback: function(value) {
              return value + '%'
            }
          },
          grid: {
            color: 'rgba(75, 85, 99, 0.3)'
          }
        },
        x: {
          ticks: {
            color: '#9ca3af',
            maxRotation: 45,
            minRotation: 45
          },
          grid: {
            color: 'rgba(75, 85, 99, 0.3)'
          }
        }
      }
    }

    const formatDate = (dateString) => {
      const date = new Date(dateString)
      return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' })
    }

    return {
      snapshots,
      loading,
      latestSnapshot,
      netWorthChange,
      netWorthChangePercent,
      netWorthChangeClass,
      chartData,
      exposureChartData,
      chartOptions,
      exposureChartOptions,
      formatCurrency,
      formatDate
    }
  }
}
</script>

<style scoped>
.charts {
  padding: 1rem 0;
}

.charts h2 {
  font-size: 1.75rem;
  margin-bottom: 2rem;
}

.loading {
  text-align: center;
  padding: 2rem;
  color: var(--text-muted);
}

.charts-container {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}

.chart-card {
  background: var(--bg-light);
  border-radius: 1rem;
  padding: 1.5rem;
  border: 2px solid var(--border);
}

.chart-card h3 {
  margin-bottom: 1.5rem;
  font-size: 1.3rem;
}

.chart-wrapper {
  height: 400px;
  position: relative;
}

.no-data {
  text-align: center;
  padding: 3rem;
  color: var(--text-muted);
  font-style: italic;
}

.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 1.5rem;
}

.stat-card {
  background: var(--bg-light);
  border-radius: 1rem;
  padding: 1.5rem;
  border: 2px solid var(--border);
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
  transition: transform 0.2s, box-shadow 0.2s;
}

.stat-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 10px 30px rgba(0, 0, 0, 0.3);
}

.stat-label {
  font-size: 0.9rem;
  color: var(--text-muted);
  font-weight: 600;
}

.stat-value {
  font-size: 1.5rem;
  font-weight: 700;
}

.stat-value.positive {
  color: var(--success);
}

.stat-value.negative {
  color: var(--danger);
}

@media (max-width: 768px) {
  .chart-wrapper {
    height: 300px;
  }

  .stats-grid {
    grid-template-columns: 1fr;
  }
}
</style>
