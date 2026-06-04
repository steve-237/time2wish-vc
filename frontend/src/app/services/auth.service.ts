import { Injectable, signal, computed, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { User } from '../models/birthday.model';
import { Observable, of } from 'rxjs';
import { catchError, map, tap } from 'rxjs/operators';

interface AuthResponse {
  token: string;
  id: number;
  email: string;
  fullName: string;
  bio?: string;
  avatarUrl?: string;
}

@Injectable({
  providedIn: 'root'
})
export class AuthService {
  private readonly http = inject(HttpClient);
  private readonly API_URL = 'http://localhost:8081/api/auth';
  private readonly STORAGE_USER_KEY = 't2w_user_profile';

  // Signals
  readonly accessToken = signal<string | null>(null);
  readonly currentUser = signal<User | null>(this.getStoredProfile());
  readonly isAuthenticated = computed(() => this.accessToken() !== null && this.currentUser() !== null);
  readonly isLoaded = signal<boolean>(false);

  constructor() {
    // Attempt auto-login on startup using refresh token cookie
    this.refreshSession().subscribe({
      next: () => this.isLoaded.set(true),
      error: () => {
        this.clearSession();
        this.isLoaded.set(true);
      }
    });
  }

  private getStoredProfile(): User | null {
    try {
      const data = localStorage.getItem(this.STORAGE_USER_KEY);
      return data ? JSON.parse(data) : null;
    } catch {
      return null;
    }
  }

  login(email: string, password: string): Observable<boolean> {
    return this.http.post<AuthResponse>(`${this.API_URL}/login`, { email, password }, { withCredentials: true }).pipe(
      tap(res => this.saveSession(res)),
      map(() => true),
      catchError(() => of(false))
    );
  }

  register(email: string, password: string, fullName: string): Observable<boolean> {
    return this.http.post(`${this.API_URL}/register`, { email, password, fullName }).pipe(
      map(() => true),
      catchError(() => of(false))
    );
  }

  refreshSession(): Observable<boolean> {
    return this.http.post<AuthResponse>(`${this.API_URL}/refresh`, {}, { withCredentials: true }).pipe(
      tap(res => this.saveSession(res)),
      map(() => true),
      catchError(err => {
        this.clearSession();
        throw err;
      })
    );
  }

  logout(): Observable<boolean> {
    return this.http.post(`${this.API_URL}/logout`, {}, { withCredentials: true }).pipe(
      tap(() => this.clearSession()),
      map(() => true),
      catchError(() => {
        this.clearSession();
        return of(true);
      })
    );
  }

  private saveSession(res: AuthResponse): void {
    const user: User = {
      id: res.id,
      email: res.email,
      fullName: res.fullName,
      bio: res.bio,
      avatarUrl: res.avatarUrl,
      status: 'ACTIVE'
    };
    
    this.accessToken.set(res.token);
    this.currentUser.set(user);
    localStorage.setItem(this.STORAGE_USER_KEY, JSON.stringify(user));
  }

  private clearSession(): void {
    this.accessToken.set(null);
    this.currentUser.set(null);
    localStorage.removeItem(this.STORAGE_USER_KEY);
  }
}
