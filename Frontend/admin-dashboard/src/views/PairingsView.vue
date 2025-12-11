<template>
  <div>
    <h1 class="text-2xl font-bold mb-6">Pairing Management</h1>
    <div class="bg-white shadow-md rounded-lg p-6 mb-6">
      <h2 class="text-xl font-semibold mb-4">Create New Pairing</h2>
      <div class="grid grid-cols-1 md:grid-cols-3 gap-4 items-end">
        <div>
          <label for="caregiver-select" class="block text-sm font-medium text-gray-700 mb-2">Select Caregiver</label>
          <select id="caregiver-select" v-model="selectedCaregiverId" class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500">
            <option value="">Choose a caregiver...</option>
            <option v-for="caregiver in caregivers" :key="caregiver.id" :value="caregiver.id">
              {{ caregiver.name }} ({{ caregiver.username }})
            </option>
          </select>
        </div>
        <div>
          <label for="child-select" class="block text-sm font-medium text-gray-700 mb-2">Select Child</label>
          <select id="child-select" v-model="selectedChildId" class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500">
            <option value="">Choose a child...</option>
            <option v-for="child in children" :key="child.id" :value="child.id">
              {{ child.name }} ({{ child.username }})
            </option>
          </select>
        </div>
        <div>
          <button 
            @click="createNewPairing" 
            :disabled="!selectedCaregiverId || !selectedChildId"
            class="w-full px-4 py-2 bg-indigo-600 text-white rounded-md hover:bg-indigo-700 disabled:bg-gray-300 disabled:cursor-not-allowed"
          >
            Create Pairing
          </button>
        </div>
      </div>
    </div>
    <div class="bg-white shadow-md rounded-lg">
      <div class="px-6 py-4 border-b border-gray-200">
        <h2 class="text-xl font-semibold">Current Pairings</h2>
      </div>
      <div class="overflow-x-auto">
        <table class="min-w-full divide-y divide-gray-200">
          <thead class="bg-gray-50">
            <tr>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Caregiver</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Child</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Created</th>
              <th class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
            </tr>
          </thead>
          <tbody class="bg-white divide-y divide-gray-200">
            <tr v-if="pairings.length === 0">
              <td colspan="4" class="px-6 py-4 text-center text-gray-500">No pairings found</td>
            </tr>
            <tr v-for="pairing in pairings" :key="pairing.id">
              <td class="px-6 py-4 whitespace-nowrap">
                <div>
                  <div class="font-medium text-gray-900">{{ pairing.caregiver.name }}</div>
                  <div class="text-sm text-gray-500">{{ pairing.caregiver.username }}</div>
                </div>
              </td>
              <td class="px-6 py-4 whitespace-nowrap">
                <div>
                  <div class="font-medium text-gray-900">{{ pairing.child.name }}</div>
                  <div class="text-sm text-gray-500">{{ pairing.child.username }}</div>
                </div>
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                {{ formatDate(pairing.createdAt) }}
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                <button 
                  @click="removePairing(pairing.id)"
                  class="text-red-600 hover:text-red-900"
                >
                  Remove Pairing
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue';
import { getCaregivers } from '@/api/caregivers';
import { getChildren } from '@/api/children';
import { getPairings, createPairing, deletePairing, type Pairing } from '@/api/pairings';
import type { UserGetDTO } from '@/interfaces/User';

const caregivers = ref<UserGetDTO[]>([]);
const children = ref<UserGetDTO[]>([]);
const pairings = ref<Pairing[]>([]);
const selectedCaregiverId = ref('');
const selectedChildId = ref('');

const fetchCaregivers = async () => {
  try {
    caregivers.value = await getCaregivers();
  } catch (error) {
    console.error('Failed to fetch caregivers:', error);
  }
};

const fetchChildren = async () => {
  try {
    children.value = await getChildren();
  } catch (error) {
    console.error('Failed to fetch children:', error);
  }
};

const fetchPairings = async () => {
  try {
    pairings.value = await getPairings();
  } catch (error) {
    console.error('Failed to fetch pairings:', error);
  }
};

const createNewPairing = async () => {
  if (!selectedCaregiverId.value || !selectedChildId.value) return;
  
  try {
    await createPairing({
      caregiverId: selectedCaregiverId.value,
      childId: selectedChildId.value
    });
    
    selectedCaregiverId.value = '';
    selectedChildId.value = '';
    
    await fetchPairings();
    console.log('Pairing created successfully!');
  } catch (error) {
    console.error('Failed to create pairing:', error);
  }
};

const removePairing = async (pairingId: string) => {
  try {
    await deletePairing(pairingId);
    await fetchPairings();
    console.log('Pairing removed successfully!');
  } catch (error) {
    console.error('Failed to remove pairing:', error);
  }
};

const formatDate = (dateString: string) => {
  return new Date(dateString).toLocaleDateString();
};

onMounted(() => {
  fetchCaregivers();
  fetchChildren();
  fetchPairings();
});
</script>
