export interface User {
  id: number;
  email: string;
  fullName: string;
  bio?: string;
  avatarUrl?: string;
  status: 'PENDING' | 'ACTIVE' | 'BANNED' | 'DELETED';
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
  isDeleted: boolean;
  createdAt: string;
}

export interface BirthdayStats {
  total: number;
  todayCount: number;
  thisMonthCount: number;
  next30DaysCount: number;
  categoryDistribution: { [key in BirthdayCategory]?: number };
}
