<template>
  <div>
    <h1 class="text-2xl font-bold mb-4">Users</h1>
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
          <tr v-for="user in users" :key="user.id">
            <td class="px-6 py-4 whitespace-nowrap">{{ user.name }}</td>
            <td class="px-6 py-4 whitespace-nowrap">{{ user.username }}</td>
            <td class="px-6 py-4 whitespace-nowrap">{{ user.role }}</td>
            <td class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
              <button @click="deleteUser(user.id)" class="text-red-600 hover:text-red-900">Delete</button>
              <button @click="makeAdmin(user.id)" class="text-indigo-600 hover:text-indigo-900 ml-4">Make Admin</button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue';
import { getAllUsers, deleteUser as apiDeleteUser, convertToAdmin } from '@/api/users';
import type { UserGetDTO } from '@/interfaces/User';

const users = ref<UserGetDTO[]>([]);

const fetchUsers = async () => {
  try {
    const rawUsers = await getAllUsers();
    users.value = rawUsers;
  } catch (error) {
    console.error('Failed to fetch users:', error);
  }
};

const deleteUser = async (id: string) => {
  try {
    await apiDeleteUser(id);
    fetchUsers();
  } catch (error) {
    console.error('Failed to delete user:', error);
  }
};

const makeAdmin = async (id: string) => {
    try {
        await convertToAdmin(id);
        fetchUsers();
    } catch (error) {
        console.error('Failed to make user an admin:', error);
    }
}

onMounted(fetchUsers);
</script>
