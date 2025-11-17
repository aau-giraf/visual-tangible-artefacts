<template>
  <div class="flex h-screen bg-gray-100">
    <aside class="w-64 bg-gray-800 text-white flex-shrink-0">
      <div class="p-4 text-2xl font-bold">Admin Dashboard</div>
      <nav>
        <ul>
          <li><router-link to="/dashboard/users" class="block p-4 hover:bg-gray-700">Users</router-link></li>
          <li><router-link to="/dashboard/caregivers" class="block p-4 hover:bg-gray-700">Caregivers</router-link></li>
          <li><router-link to="/dashboard/children" class="block p-4 hover:bg-gray-700">Children</router-link></li>
          <li><router-link to="/dashboard/pairings" class="block p-4 hover:bg-gray-700">Pairings</router-link></li>
          <li><router-link to="/dashboard/admins" class="block p-4 hover:bg-gray-700">Admin Management</router-link></li>
        </ul>
      </nav>
      <div class="absolute bottom-0 w-64">
        <button @click="logout" class="w-full p-4 text-left hover:bg-gray-700">Logout</button>
      </div>
    </aside>
    <main class="flex-1 flex flex-col overflow-hidden">
      <header class="bg-white shadow p-4 flex justify-between items-center">
        <h1 class="text-xl font-semibold">Welcome, Admin</h1>
      </header>
      <div class="flex-1 overflow-x-hidden overflow-y-auto bg-gray-200 p-4">
        <router-view></router-view>
      </div>
    </main>
  </div>
</template>

<script setup lang="ts">
import { useAuthStore } from '@/store/auth';

const authStore = useAuthStore();

const logout = () => {
  authStore.logout();
};
</script>
