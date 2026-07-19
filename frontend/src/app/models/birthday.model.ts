export interface User {
  id: number;
  email: string;
  fullName: string;
  bio?: string;
  avatarUrl?: string;
  status: string;
  roles?: string[];
  plan?: string;
  badges?: string[];
  lastAiWishGeneration?: string;
  lastAiGiftGeneration?: string;
  coins: number;
}

export type BirthdayCategory = 'Family' | 'Friend' | 'Work' | 'Other';

export interface Birthday {
  id: number;
  userId: number;
  name: string;
  birthdate: string; // ISO format 'YYYY-MM-DD'
  category: BirthdayCategory;
  photoUrl?: string;
  notes?: string;
  reminderDays: number;
  showAge?: boolean;
  email?: string;
  whatsapp?: string;
  gender?: 'Masculin' | 'Féminin' | 'Autre';
  isDeleted: boolean;
  interests?: string[];
  isFavorite?: boolean;
  shareToken?: string;
  // Party Details
  partyDate?: string;
  partyTime?: string;
  partyLocation?: string;
  partyDescription?: string;
  partyTasks?: PartyTask[];
  memories?: MemoryItem[];
  signatures?: ECardSignature[];
}

export interface PartyTask {
  id: number;
  birthdayId: number;
  description: string;
  assigneeName?: string;
  isCompleted: boolean;
  createdAt: string;
}

export interface MemoryItem {
  id: number;
  guestName: string;
  guestSessionId: string;
  message?: string;
  mediaUrl?: string;
  mediaType?: string;
  createdAt: string;
}

export interface ECardSignature {
  id: number;
  guestName: string;
  guestSessionId: string;
  message: string;
  color: string;
  fontFamily: string;
  createdAt: string;
}

export interface GiftSuggestion {
  name: string;
  estimatedPrice: string;
  whereToBuy: string;
  purchaseLink: string;
  imageUrl?: string;
  preparationTips: string;
}

export interface Gift {
  id: number;
  birthdayId: number;
  name: string;
  description: string;
  priceRange: string;
  url: string;
  imageUrl?: string;
  isReserved: boolean;
  reservedByName?: string;
  createdAt: string;
  // Community Features
  upvotes?: number;
  downvotes?: number;
  userVote?: 'UP' | 'DOWN' | null;
}

export interface SharedBirthday {
  id: number;
  name: string;
  birthdate: string;
  showAge: boolean;
  gender?: 'Masculin' | 'Féminin' | 'Autre';
  gifts: Gift[];
  // Party Details
  partyDate?: string;
  partyTime?: string;
  partyLocation?: string;
  partyDescription?: string;
  partyTasks?: PartyTask[];
  memories?: MemoryItem[];
  signatures?: ECardSignature[];
}

export function getZodiacSign(birthdate: string): { name: string; emoji: string } {
  if (!birthdate) return { name: '', emoji: '' };
  
  const date = new Date(birthdate);
  const day = date.getDate();
  const month = date.getMonth() + 1; // 1-12

  if ((month === 3 && day >= 21) || (month === 4 && day <= 19)) return { name: 'Bélier', emoji: '♈' };
  if ((month === 4 && day >= 20) || (month === 5 && day <= 20)) return { name: 'Taureau', emoji: '♉' };
  if ((month === 5 && day >= 21) || (month === 6 && day <= 20)) return { name: 'Gémeaux', emoji: '♊' };
  if ((month === 6 && day >= 21) || (month === 7 && day <= 22)) return { name: 'Cancer', emoji: '♋' };
  if ((month === 7 && day >= 23) || (month === 8 && day <= 22)) return { name: 'Lion', emoji: '♌' };
  if ((month === 8 && day >= 23) || (month === 9 && day <= 22)) return { name: 'Vierge', emoji: '♍' };
  if ((month === 9 && day >= 23) || (month === 10 && day <= 22)) return { name: 'Balance', emoji: '♎' };
  if ((month === 10 && day >= 23) || (month === 11 && day <= 21)) return { name: 'Scorpion', emoji: '♏' };
  if ((month === 11 && day >= 22) || (month === 12 && day <= 21)) return { name: 'Sagittaire', emoji: '♐' };
  if ((month === 12 && day >= 22) || (month === 1 && day <= 19)) return { name: 'Capricorne', emoji: '♑' };
  if ((month === 1 && day >= 20) || (month === 2 && day <= 18)) return { name: 'Verseau', emoji: '♒' };
  if ((month === 2 && day >= 19) || (month === 3 && day <= 20)) return { name: 'Poissons', emoji: '♓' };

  return { name: '', emoji: '' };
}

export interface BirthdayStats {
  total: number;
  todayCount: number;
  thisMonthCount: number;
  next30DaysCount: number;
  categoryDistribution: { [key in BirthdayCategory]?: number };
}
