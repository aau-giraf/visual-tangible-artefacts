import { defineStore } from 'pinia';
import { ref } from 'vue';
import { login as apiLogin } from '@/api/auth';
import type { UserLoginDTO } from '@/interfaces/Auth';
import router from '@/router';

export const useAuthStore = defineStore('auth', () => {
  const token = ref(localStorage.getItem('token') || '');
  const user = ref(JSON.parse(localStorage.getItem('user') || '{}'));
  const isAuthenticated = ref(!!token.value);

  async function login(credentials: UserLoginDTO) {
    // LOCAL LOGIN - Comment out this block when pushing to GitHub
    // ============================================================
    token.value = 'local-mock-token';
    user.value = { id: 'local-user-id' };
    isAuthenticated.value = true;
    localStorage.setItem('token', token.value);
    localStorage.setItem('user', JSON.stringify(user.value));
    router.push('/dashboard');
    return;
    // ============================================================

    try {
      const response = await apiLogin(credentials);
      token.value = response.token;
      // For simplicity, we're not fetching user details here.
      // In a real app, you'd likely fetch and store user info.
      user.value = { id: response.userId };
      isAuthenticated.value = true;
      localStorage.setItem('token', token.value);
      localStorage.setItem('user', JSON.stringify(user.value));
      router.push('/dashboard');
    } catch (error) {
      console.error('Login failed:', error);
      throw error;
    }
  }

  function logout() {
    token.value = '';
    user.value = {};
    isAuthenticated.value = false;
    localStorage.removeItem('token');
    localStorage.removeItem('user');
    router.push('/login');
  }

  return { token, user, isAuthenticated, login, logout };
});
