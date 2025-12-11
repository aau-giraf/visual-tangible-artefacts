import apiClient from './axios';

export interface CreatePairingRequest {
  caregiverId: string;
  childId: string;
}

export interface Pairing {
  id: string;
  caregiverId: string;
  childId: string;
  caregiver: { id: string; name: string; username: string };
  child: { id: string; name: string; username: string };
  createdAt: string;
}

export const getPairings = (): Promise<Pairing[]> => {
  return apiClient.get('/Admin/pairings').then(res => res.data);
};

export const createPairing = (data: CreatePairingRequest): Promise<void> => {
  return apiClient.post('/Admin/pairings', data).then(res => res.data);
};

export const deletePairing = (id: string): Promise<void> => {
  return apiClient.delete(`/Admin/pairings/${id}`).then(res => res.data);
};
