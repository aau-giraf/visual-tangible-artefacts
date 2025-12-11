import apiClient from './axios';
import type { UserGetDTO } from '@/interfaces/User';

export const getCaregivers = (): Promise<UserGetDTO[]> => {
  return apiClient.get('/Admin/caregivers').then(res => res.data);
};
