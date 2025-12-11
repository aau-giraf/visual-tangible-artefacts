<template>
  <div class="flex h-screen bg-stone-50 font-sans text-stone-800 overflow-hidden">
    <!-- Sidebar -->
    <aside class="w-[250px] bg-stone-50 border-r border-stone-200 flex flex-col z-20 flex-shrink-0">
      <!-- Sidebar Header -->
      <div class="h-16 flex items-center px-6">
         <div class="flex items-center gap-3">
            <div class="h-8 w-8 bg-teal-600 rounded-lg text-white flex items-center justify-center shadow-sm">
                <component :is="Sun" class="w-4 h-4" />
            </div>
            <span class="text-base font-bold tracking-tight text-stone-800">VTA Admin</span>
         </div>
      </div>

      <!-- Navigation -->
      <nav class="flex-1 overflow-y-auto py-6 px-3 space-y-1">
        <!-- Analytics -->
        <router-link to="/dashboard/overview" class="flex items-center gap-3 px-3 py-2.5 text-sm font-medium rounded-xl transition-all text-stone-600 hover:bg-white hover:shadow-sm hover:text-teal-700" active-class="bg-white shadow-sm text-teal-700 ring-1 ring-black/5">
            <component :is="LayoutDashboard" class="w-4 h-4" />
            Oversigt
        </router-link>

        <div class="my-4 mx-3 h-px bg-stone-200/60"></div>

        <!-- Management -->
        <div class="px-3 mb-2 text-[11px] font-semibold text-stone-400 uppercase tracking-wider">Administration</div>
        
        <router-link to="/dashboard/children" class="flex items-center gap-3 px-3 py-2.5 text-sm font-medium rounded-xl transition-all text-stone-600 hover:bg-white hover:shadow-sm hover:text-teal-700" active-class="bg-white shadow-sm text-teal-700 ring-1 ring-black/5">
             <component :is="Baby" class="w-4 h-4" />
            Elever
        </router-link>
        
        <router-link to="/dashboard/caregivers" class="flex items-center gap-3 px-3 py-2.5 text-sm font-medium rounded-xl transition-all text-stone-600 hover:bg-white hover:shadow-sm hover:text-teal-700" active-class="bg-white shadow-sm text-teal-700 ring-1 ring-black/5">
             <component :is="HeartHandshake" class="w-4 h-4" />
            Personale
        </router-link>
        
         <router-link to="/dashboard/users" class="flex items-center gap-3 px-3 py-2.5 text-sm font-medium rounded-xl transition-all text-stone-600 hover:bg-white hover:shadow-sm hover:text-teal-700" active-class="bg-white shadow-sm text-teal-700 ring-1 ring-black/5">
             <component :is="Users" class="w-4 h-4" />
            Brugere
        </router-link>
        
         <router-link to="/dashboard/pairings" class="flex items-center gap-3 px-3 py-2.5 text-sm font-medium rounded-xl transition-all text-stone-600 hover:bg-white hover:shadow-sm hover:text-teal-700" active-class="bg-white shadow-sm text-teal-700 ring-1 ring-black/5">
             <component :is="Link" class="w-4 h-4" />
            Koblinger
        </router-link>

        <div class="my-4 mx-3 h-px bg-stone-200/60"></div>

        <!-- Settings -->
         <router-link to="/dashboard/admins" class="flex items-center gap-3 px-3 py-2.5 text-sm font-medium rounded-xl transition-all text-stone-600 hover:bg-white hover:shadow-sm hover:text-teal-700" active-class="bg-white shadow-sm text-teal-700 ring-1 ring-black/5">
             <component :is="Settings" class="w-4 h-4" />
            Indstillinger
        </router-link>
      </nav>

      <!-- Footer User -->
      <div class="p-4 border-t border-stone-200/60">
         <button @click="logout" class="flex items-center gap-3 w-full px-3 py-2.5 text-sm font-medium text-stone-600 rounded-xl hover:bg-red-50 hover:text-red-700 transition-colors">
            <component :is="LogOut" class="w-4 h-4" />
            Log ud
         </button>
      </div>
    </aside>

    <!-- Main Content Area -->
    <div class="flex-1 flex flex-col min-w-0 overflow-hidden bg-stone-50">
      <!-- Top Navbar -->
      <header class="h-16 flex items-center justify-between px-8 border-b border-stone-200/60 bg-stone-50/80 backdrop-blur-sm z-10">
         <!-- Breadcrumbs -->
         <div class="flex items-center text-sm text-stone-500">
             <span class="text-stone-400">Dashboard</span>
             <component :is="ChevronRight" class="w-4 h-4 mx-2 text-stone-300" />
             <span class="font-medium text-stone-800">{{ currentRouteNameDanish }}</span>
         </div>

         <!-- Right Actions -->
         <div class="flex items-center gap-4">
            <button class="p-2 rounded-full text-stone-400 hover:text-teal-700 hover:bg-white hover:shadow-sm transition-all relative">
                <component :is="Bell" class="w-5 h-5" />
                <span class="absolute top-2 right-2 w-2 h-2 bg-teal-500 rounded-full border-2 border-stone-50"></span>
            </button>
            <div class="h-9 w-9 rounded-full bg-white border border-stone-200 shadow-sm flex items-center justify-center text-xs font-bold text-teal-800">
                AD
            </div>
         </div>
      </header>

      <!-- Page Content -->
      <main class="flex-1 overflow-x-hidden overflow-y-auto p-8">
         <router-view v-slot="{ Component }">
           <transition name="fade" mode="out-in">
             <component :is="Component" />
           </transition>
         </router-view>
      </main>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue';
import { useRoute } from 'vue-router';
import { useAuthStore } from '@/store/auth';
import { 
    LayoutDashboard, 
    Users, 
    HeartHandshake, 
    Baby, 
    Link, 
    Settings, 
    LogOut, 
    Sun,
    ChevronRight,
    Bell
} from 'lucide-vue-next';

const authStore = useAuthStore();
const route = useRoute();

const currentRouteNameDanish = computed(() => {
    const map: Record<string, string> = {
        'Overview': 'Oversigt',
        'Users': 'Brugere',
        'Caregivers': 'Personale',
        'Children': 'Elever',
        'Pairings': 'Koblinger',
        'Admins': 'Indstillinger'
    };
    return map[route.name as string] || route.name;
});

const logout = () => {
  authStore.logout();
};
</script>

<style scoped>
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.2s ease;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}
</style>
