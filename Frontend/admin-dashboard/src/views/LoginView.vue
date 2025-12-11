<template>
  <div class="min-h-screen flex items-center justify-center bg-stone-50 py-12 px-4 sm:px-6 lg:px-8 font-sans text-stone-800">
    <div class="max-w-md w-full space-y-8 bg-white p-10 rounded-2xl border border-stone-200">
      <div class="text-center">
        <div class="mx-auto h-12 w-12 bg-teal-600 rounded-xl flex items-center justify-center text-white mb-6">
           
           <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-sun"><circle cx="12" cy="12" r="4"/><path d="M12 2v2"/><path d="M12 20v2"/><path d="m4.93 4.93 1.41 1.41"/><path d="m17.66 17.66 1.41 1.41"/><path d="M2 12h2"/><path d="M20 12h2"/><path d="m6.34 17.66-1.41 1.41"/><path d="m19.07 4.93-1.41 1.41"/></svg>
        </div>
        <h2 class="text-2xl font-semibold tracking-tight text-stone-800">Velkommen tilbage</h2>
        <p class="mt-2 text-sm text-stone-500">
          Log ind for at få adgang til VTA-platformen
        </p>
      </div>
      
      <form class="mt-8 space-y-6" @submit.prevent="handleLogin">
        <div class="space-y-4">
          <div>
            <label for="username" class="block text-sm font-medium text-stone-700 mb-1">Brugernavn</label>
            <input 
              id="username" 
              name="username" 
              type="text" 
              v-model="username"
              required 
              class="appearance-none relative block w-full px-4 py-2.5 border border-stone-200 placeholder-stone-400 text-stone-800 rounded-xl focus:outline-none focus:ring-2 focus:ring-teal-600/20 focus:border-teal-600 sm:text-sm bg-white transition-all" 
              placeholder="Indtast dit brugernavn"
            >
          </div>
          
          <div>
             <label for="password" class="block text-sm font-medium text-stone-700 mb-1">Adgangskode</label>
             <input 
              id="password" 
              name="password" 
              type="password" 
              v-model="password"
              required 
              class="appearance-none relative block w-full px-4 py-2.5 border border-stone-200 placeholder-stone-400 text-stone-800 rounded-xl focus:outline-none focus:ring-2 focus:ring-teal-600/20 focus:border-teal-600 sm:text-sm bg-white transition-all" 
              placeholder="Indtast din adgangskode"
            >
          </div>
        </div>

        <div class="flex items-center justify-between">
          <div class="flex items-center">
            <input 
              id="remember-me" 
              name="remember-me" 
              type="checkbox" 
              class="h-4 w-4 text-teal-600 focus:ring-teal-600 border-stone-300 rounded"
            >
            <label for="remember-me" class="ml-2 block text-sm text-stone-500">
              Husk mig
            </label>
          </div>

          <div class="text-sm">
            <a href="#" class="font-medium text-teal-700 hover:text-teal-600">
              Glemt adgangskode?
            </a>
          </div>
        </div>

        
        <div v-if="error" class="rounded-lg bg-red-50 p-3 border border-red-100">
          <div class="flex">
             <div class="flex-shrink-0">
                <svg class="h-5 w-5 text-red-400" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
                   <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd" />
                </svg>
             </div>
             <div class="ml-3">
                <h3 class="text-sm font-medium text-red-800">Ugyldigt brugernavn eller adgangskode</h3>
             </div>
          </div>
        </div>

        <div>
          <button 
            type="submit" 
            :disabled="isLoading"
            class="group relative w-full flex justify-center py-2.5 px-4 border border-transparent text-sm font-medium rounded-xl text-white bg-teal-700 hover:bg-teal-800 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-teal-600 disabled:opacity-70 disabled:cursor-not-allowed transition-all h-11 items-center shadow-sm"
          >
             <span v-if="!isLoading">Log ind</span>
             <svg v-else class="animate-spin -ml-1 mr-3 h-4 w-4 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
             </svg>
          </button>
        </div>
      </form>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue';
import { useAuthStore } from '@/store/auth';
import { useRouter } from 'vue-router';

const username = ref('');
const password = ref('');
const isLoading = ref(false);
const error = ref(false);

const authStore = useAuthStore();
const router = useRouter();

const handleLogin = async () => {
  isLoading.value = true;
  error.value = false;
  
  try {
    await authStore.login({ username: username.value, password: password.value });
    router.push('/dashboard');
  } catch (e) {
    error.value = true;
    console.error("Login failed", e);
  } finally {
    isLoading.value = false;
  }
};
</script>
