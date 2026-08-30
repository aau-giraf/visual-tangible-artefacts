import apiClient from './axios';
import type { UserGetDTO } from '@/interfaces/User';

export const getAllUsers = (): Promise<UserGetDTO[]> => {
  return apiClient.get('/Users').then(res => res.data.items);
};

export const deleteUser = (id: string): Promise<void> => {
  return apiClient.delete(`/Admin/users/${id}`).then(res => res.data);
};

export const convertToAdmin = (id: string): Promise<void> => {
    return apiClient.post(`/Admin/users/${id}/make-admin`).then(res => res.data);
}
