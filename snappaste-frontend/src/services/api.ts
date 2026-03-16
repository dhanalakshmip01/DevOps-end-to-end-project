import axios from 'axios';
import type { CreatePasteRequest, Paste } from '../types/paste';

const api = axios.create({
  baseURL: '/api',
  headers: { 'Content-Type': 'application/json' },
});

export const pasteService = {
  create: (data: CreatePasteRequest): Promise<Paste> =>
    api.post<Paste>('/pastes', data).then((r) => r.data),

  getByCode: (shortCode: string): Promise<Paste> =>
    api.get<Paste>(`/pastes/${shortCode}`).then((r) => r.data),

  deleteByCode: (shortCode: string): Promise<void> =>
    api.delete(`/pastes/${shortCode}`).then(() => undefined),
};
