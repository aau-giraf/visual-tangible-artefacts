import apiClient from './axios';
import type { UserGetDTO } from '@/interfaces/User';

export const getChildren = (): Promise<UserGetDTO[]> => {
  return apiClient.get('/Admin/children').then(res => res.data);
};
