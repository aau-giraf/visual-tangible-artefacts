import axios from 'axios';
import { useAuthStore } from '@/store/auth';

const apiClient = axios.create({
  baseURL: 'http://10.0.0.4:5192/api/', // Adjust to your backend URL
  headers: {
    'Content-Type': 'application/json',
  },
});

apiClient.interceptors.request.use(
  (config) => {
    const authStore = useAuthStore();
    const token = authStore.token;
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

export default apiClient;
