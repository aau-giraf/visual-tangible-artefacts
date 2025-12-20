<template>
  <div class="space-y-8 max-w-[1600px] mx-auto">
    <div class="flex items-center justify-between">
      <div>
        <h1 class="text-xl font-semibold text-stone-800 tracking-tight">Oversigt</h1>
        <p class="text-sm text-stone-500 mt-1">Velkommen tilbage til skoleadministrationen</p>
      </div>
      <div class="flex items-center space-x-3 bg-white rounded-xl px-3 py-1.5 border border-stone-200 shadow-sm">
         <span class="w-2 h-2 rounded-full bg-teal-500 animate-pulse"></span>
         <span class="text-xs text-stone-600 font-medium">Systemet kører normalt</span>
      </div>
    </div>

    <!-- KPI Grid -->
    <div class="grid grid-cols-1 md:grid-cols-4 gap-6">
      <!-- Active Students Card -->
      <div class="bg-white rounded-2xl border border-stone-200 p-6 hover:border-teal-200/50 hover:shadow-md transition-all group cursor-default">
        <div class="flex flex-col h-full justify-between">
            <div class="flex justify-between items-start">
                <span class="text-xs font-bold text-stone-400 uppercase tracking-wider">Aktive Elever</span>
                <div class="p-1.5 bg-stone-50 rounded-lg text-stone-400 group-hover:text-teal-600 group-hover:bg-teal-50 transition-colors">
                    <component :is="Users" class="w-4 h-4" />
                </div>
            </div>
            <div class="mt-4">
                <div class="flex items-baseline gap-2">
                    <span class="text-3xl font-bold text-stone-800 tracking-tight">00</span>
                </div>
                <p class="text-xs text-stone-500 mt-1">Aktive på VTA</p>
            </div>
        </div>
      </div>

      
      <div class="bg-white rounded-2xl border border-stone-200 p-6 hover:border-teal-200/50 hover:shadow-md transition-all group cursor-default">
        <div class="flex flex-col h-full justify-between">
            <div class="flex justify-between items-start">
                <span class="text-xs font-bold text-stone-400 uppercase tracking-wider">Tekst</span>
                 <div class="p-1.5 bg-stone-50 rounded-lg text-stone-400 group-hover:text-teal-600 group-hover:bg-teal-50 transition-colors">
                    <component :is="CalendarCheck" class="w-4 h-4" />
                </div>
            </div>
            <div class="mt-4">
                <div class="flex items-baseline gap-2">
                    <span class="text-3xl font-bold text-stone-800 tracking-tight">94%</span>
                    <span class="text-xs font-semibold text-teal-600 bg-teal-50 px-2 py-0.5 rounded-full">+2%</span>
                </div>
                <p class="text-xs text-stone-500 mt-1">Tekst</p>
            </div>
        </div>
      </div>

      
      <div class="bg-white rounded-2xl border border-stone-200 p-6 hover:border-orange-200/50 hover:shadow-md transition-all group cursor-default">
        <div class="flex flex-col h-full justify-between">
            <div class="flex justify-between items-start">
                <span class="text-xs font-bold text-stone-400 uppercase tracking-wider">Tekst</span>
                 <div class="p-1.5 bg-stone-50 rounded-lg text-stone-400 group-hover:text-orange-600 group-hover:bg-orange-50 transition-colors">
                    <component :is="FileText" class="w-4 h-4" />
                </div>
            </div>
            <div class="mt-4">
                <div class="flex items-baseline gap-2">
                    <span class="text-3xl font-bold text-stone-800 tracking-tight">3</span>
                </div>
                 <p class="text-xs text-stone-500 mt-1">Tekst</p>
            </div>
        </div>
      </div>

      <div class="bg-white rounded-2xl border border-stone-200 p-6 hover:border-teal-200/50 hover:shadow-md transition-all group cursor-default">
        <div class="flex flex-col h-full justify-between">
            <div class="flex justify-between items-start">
                <span class="text-xs font-bold text-stone-400 uppercase tracking-wider">Nye Notifikationer</span>
                 <div class="p-1.5 bg-stone-50 rounded-lg text-stone-400 group-hover:text-teal-600 group-hover:bg-teal-50 transition-colors">
                    <component :is="Bell" class="w-4 h-4" />
                </div>
            </div>
            <div class="mt-4">
                <div class="flex items-baseline gap-2">
                    <span class="text-3xl font-bold text-stone-800 tracking-tight">8</span>
                </div>
                 <p class="text-xs text-stone-500 mt-1">Opdateringer siden sidste login</p>
            </div>
        </div>
      </div>
    </div>

    <!-- Activity Chart -->
    <div class="bg-white rounded-2xl border border-stone-200 p-8 shadow-sm">
        <div class="flex items-center justify-between mb-8">
            <div>
                <h3 class="text-base font-bold text-stone-800">Daglig brugere %</h3>
                <p class="text-sm text-stone-500 mt-1">Oversigt VTA aktiviter (eller noget) de seneste 7 dage</p>
            </div>
            <!-- Legend / Actions could go here -->
        </div>
        
        <div class="w-full h-80">
            <apexchart 
                width="100%" 
                height="100%" 
                type="area" 
                :options="chartOptions" 
                :series="series"
            ></apexchart>
        </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue';
import VueApexCharts from 'vue3-apexcharts';
import { Users, CalendarCheck, FileText, Bell } from 'lucide-vue-next';

// Register ApexCharts component locally if not done globally
const apexchart = VueApexCharts;

// Mock Data for the Chart
const series = ref([
    {
        name: 'Tekst %',
        data: [88, 92, 95, 91, 89, 94, 96]
    }
]);

const chartOptions = ref({
    chart: {
        type: 'area',
        fontFamily: 'Inter, sans-serif',
        background: 'transparent',
        toolbar: {
            show: false
        },
        zoom: {
            enabled: false
        }
    },
    colors: ['#0d9488'], // Teal-600
    dataLabels: {
        enabled: false
    },
    stroke: {
        curve: 'smooth',
        width: 2
    },
    fill: {
        type: 'gradient',
        gradient: {
            shadeIntensity: 1,
            opacityFrom: 0.2,
            opacityTo: 0.0,
            stops: [0, 90, 100]
        }
    },
    xaxis: {
        categories: ['Man', 'Tir', 'Ons', 'Tor', 'Fre', 'Lør', 'Søn'],
        axisBorder: {
            show: false
        },
        axisTicks: {
            show: false
        },
        labels: {
            style: {
                colors: '#a8a29e', // stone-400
                fontSize: '12px',
                fontFamily: 'Inter, sans-serif',
                fontWeight: 500
            },
            offsetY: 5
        },
        tooltip: {
            enabled: false
        }
    },
    yaxis: {
        show: true, 
        min: 80,
        max: 100,
        labels: {
             style: {
                colors: '#a8a29e', // stone-400
                fontSize: '11px',
                fontFamily: 'Inter, sans-serif',
            },
            formatter: (value: number) => {
                return value.toFixed(0) + '%';
            }
        }
    },
    grid: {
        borderColor: '#f5f5f4', // stone-100
        strokeDashArray: 4,
        yaxis: {
            lines: {
                show: true
            }
        },
        padding: {
            left: 10,
            right: 0
        }
    },
    tooltip: {
        theme: 'light',
        style: {
            fontSize: '12px',
            fontFamily: 'Inter, sans-serif'
        },
        x: {
            show: true
        },
        y: {
            formatter: (val: number) => val + '%'
        }
    },
    markers: {
        size: 4,
        colors: ['#fff'],
        strokeColors: '#0d9488',
        strokeWidth: 2,
        hover: {
            size: 6,
        }
    }
});
</script>
