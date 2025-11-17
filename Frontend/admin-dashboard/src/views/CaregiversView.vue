<template>
  <div>
    <h1 class="text-2xl font-bold mb-4">Caregivers</h1>
    <div class="bg-white shadow-md rounded-lg">
      <table class="min-w-full divide-y divide-gray-200">
        <thead class="bg-gray-50">
          <tr>
            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Name</th>
            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Username</th>
            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Role</th>
            <th class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
          </tr>
        </thead>
        <tbody class="bg-white divide-y divide-gray-200">
          <tr v-for="caregiver in caregivers" :key="caregiver.id">
            <td class="px-6 py-4 whitespace-nowrap">{{ caregiver.name }}</td>
            <td class="px-6 py-4 whitespace-nowrap">{{ caregiver.username }}</td>
            <td class="px-6 py-4 whitespace-nowrap">
              <span class="px-2 py-1 text-xs font-medium rounded-full bg-blue-100 text-blue-800">
                Caregiver
              </span>
            </td>
            <td class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue';
import { getCaregivers } from '@/api/caregivers';
import type { UserGetDTO } from '@/interfaces/User';

const caregivers = ref<UserGetDTO[]>([]);

const fetchCaregivers = async () => {
  try {
    caregivers.value = await getCaregivers();
  } catch (error) {
    console.error('Failed to fetch caregivers:', error);
  }
};

onMounted(fetchCaregivers);
</script>
