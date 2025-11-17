import apiClient from './axios';
import type { Admin } from '@/interfaces/Admin';
import type { UserSignupDTO } from '@/interfaces/User';

export const getAdmins = (): Promise<Admin[]> => {
  return apiClient.get('/Admin/admins').then(res => res.data);
};

export const createAdmin = (data: UserSignupDTO): Promise<Admin> => {
    return apiClient.post('/Admin/admins', data).then(res => res.data);
}

export const deleteAdmin = (id: string): Promise<void> => {
  return apiClient.delete(`/Admin/users/${id}`).then(res => res.data);
};
