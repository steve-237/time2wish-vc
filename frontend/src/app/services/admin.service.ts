import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';


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
}

export interface StatsResponse {
  totalUsers: number;
  totalBirthdays: number;
}

@Injectable({
  providedIn: 'root'
})
export class AdminService {
  private http = inject(HttpClient);
  private apiUrl = 'http://localhost:8081/api/admin';

  getStats(): Observable<StatsResponse> {
    return this.http.get<StatsResponse>(`${this.apiUrl}/stats`);
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
}
