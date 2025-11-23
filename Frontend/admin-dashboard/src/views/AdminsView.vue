<template>
  <div>
    <h1 class="text-2xl font-bold mb-4">Admin Management</h1>
    <div class="mb-4">
      <form @submit.prevent="create" class="flex gap-4">
        <input type="text" v-model="newAdmin.name" placeholder="Name" class="p-2 border rounded" required>
        <input type="text" v-model="newAdmin.username" placeholder="Username" class="p-2 border rounded" required>
        <input type="password" v-model="newAdmin.password" placeholder="Password" class="p-2 border rounded" required>
        <button type="submit" class="p-2 bg-blue-500 text-white rounded">Create Admin</button>
      </form>
    </div>
    <div class="bg-white shadow-md rounded-lg">
      <table class="min-w-full divide-y divide-gray-200">
        <thead class="bg-gray-50">
          <tr>
            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Name</th>
            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Username</th>
            <th class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
          </tr>
        </thead>
        <tbody class="bg-white divide-y divide-gray-200">
          <tr v-for="admin in admins" :key="admin.id">
            <td class="px-6 py-4 whitespace-nowrap">{{ admin.name }}</td>
            <td class="px-6 py-4 whitespace-nowrap">{{ admin.username }}</td>
            <td class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
              <button @click="deleteAdmin(admin.id)" class="text-red-600 hover:text-red-900">Delete</button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue';
import { getAdmins, createAdmin, deleteAdmin as apiDeleteAdmin } from '@/api/admins';
import type { Admin } from '@/interfaces/Admin';
import type { UserSignupDTO } from '@/interfaces/User';
import { UserRole } from '@/interfaces/User';

const admins = ref<Admin[]>([]);
const newAdmin = ref<UserSignupDTO>({ name: '', username: '', password: '', role: UserRole.Admin });

const fetchAdmins = async () => {
  try {
    admins.value = await getAdmins();
  } catch (error) {
    console.error('Failed to fetch admins:', error);
  }
};

const create = async () => {
    try {
        await createAdmin(newAdmin.value);
        newAdmin.value = { name: '', username: '', password: '', role: UserRole.Admin };
        fetchAdmins();
    } catch (error) {
        console.error('Failed to create admin:', error);
    }
}

const deleteAdmin = async (id: string) => {
    try {
        await apiDeleteAdmin(id);
        fetchAdmins();
    } catch (error) {
        console.error('Failed to delete admin:', error);
    }
}

onMounted(fetchAdmins);
</script>
