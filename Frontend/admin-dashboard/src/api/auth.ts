import apiClient from './axios';
import type { UserLoginDTO, UserLoginResponseDTO } from '@/interfaces/Auth';

export const login = (data: UserLoginDTO): Promise<UserLoginResponseDTO> => {
  return apiClient.post('/Users/Login', data).then(res => res.data);
};
