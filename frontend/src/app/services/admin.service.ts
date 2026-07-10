import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment';

export interface AdminUserDto {
  id: number;
  email: string;
  fullName: string;
  bio?: string;
  avatarUrl?: string;
  status: string;
  lastLoginAt?: string;
  createdAt: string;
  role: string;
  plan: string;
  badges?: string[];
}

export interface StatsResponse {
  totalUsers: number;
  totalBirthdays: number;
  planDistribution?: { [key: string]: number };
  monthlyRegistrations?: { [key: string]: number };
  recentUsers?: AdminUserDto[];
  totalRevenue?: number;
  monthlyRevenue?: { [key: string]: number };
}

export interface AdminPaymentDto {
  id: number;
  userEmail: string;
  userFullName: string;
  provider: string;
  amount: number;
  currency: string;
  plan: string;
  status: string;
  providerTransactionId: string;
  createdAt: string;
}

export interface AppSetting {
  key: string;
  value: string;
  description: string;
  type: string;
}

@Injectable({
  providedIn: 'root'
})
export class AdminService {
  private http = inject(HttpClient);
  private apiUrl = environment.apiUrl + '/admin';

  getStats(): Observable<StatsResponse> {
    return this.http.get<StatsResponse>(`${this.apiUrl}/stats`);
  }

  getPayments(): Observable<AdminPaymentDto[]> {
    return this.http.get<AdminPaymentDto[]>(`${this.apiUrl}/payments`);
  }

  getSettings(): Observable<AppSetting[]> {
    return this.http.get<AppSetting[]>(`${this.apiUrl}/settings`);
  }

  updateSetting(key: string, value: string): Observable<AppSetting> {
    return this.http.put<AppSetting>(`${this.apiUrl}/settings/${key}`, { value });
  }

  getAllUsers(): Observable<AdminUserDto[]> {
    return this.http.get<AdminUserDto[]>(`${this.apiUrl}/users`);
  }

  updateUserStatus(id: number, status: string): Observable<any> {
    return this.http.put(`${this.apiUrl}/users/${id}/status`, { status });
  }

  updateUserPlan(id: number, plan: string): Observable<any> {
    return this.http.put(`${this.apiUrl}/users/${id}/plan`, { plan });
  }

  updateUserRole(id: number, role: string): Observable<any> {
    return this.http.put(`${this.apiUrl}/users/${id}/role`, { role });
  }

  deleteUser(id: number): Observable<any> {
    return this.http.delete(`${this.apiUrl}/users/${id}`);
  }

  addBadge(userId: number, badgeName: string): Observable<any> {
    return this.http.post(`${this.apiUrl}/users/${userId}/badges`, { badgeName });
  }

  removeBadge(userId: number, badgeName: string): Observable<any> {
    return this.http.delete(`${this.apiUrl}/users/${userId}/badges/${badgeName}`);
  }
}
