import { Injectable, signal, computed, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { User } from '../models/birthday.model';
import { Observable, of } from 'rxjs';
import { catchError, map, tap } from 'rxjs/operators';
import { environment } from '../../environments/environment';

interface AuthResponse {
  token: string;
  id: number;
  email: string;
  fullName: string;
  bio?: string;
  avatarUrl?: string;
  roles: string[];
  plan?: string;
}

@Injectable({
  providedIn: 'root'
})
export class AuthService {
  private readonly http = inject(HttpClient);
  private readonly API_URL = environment.apiUrl + '/auth';
  private readonly STORAGE_USER_KEY = 't2w_user_profile';
  private readonly STORAGE_TOKEN_KEY = 't2w_access_token';

  // Signals
  readonly accessToken = signal<string | null>(this.getStoredToken());
  readonly currentUser = signal<User | null>(this.getStoredProfile());
  readonly isAuthenticated = computed(() => this.accessToken() !== null && this.currentUser() !== null);
  readonly isLoaded = signal<boolean>(false);

  constructor() {
    // Session initialization is handled by APP_INITIALIZER in app.config.ts
  }

  private getStoredProfile(): User | null {
    try {
      const data = localStorage.getItem(this.STORAGE_USER_KEY);
      return data ? JSON.parse(data) : null;
    } catch {
      return null;
    }
  }

  private getStoredToken(): string | null {
    return localStorage.getItem(this.STORAGE_TOKEN_KEY);
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

  updateProfile(fullName: string, bio: string, avatarUrl: string): Observable<boolean> {
    return this.http.put<AuthResponse>(`${this.API_URL}/profile`, { fullName, bio, avatarUrl }, { withCredentials: true }).pipe(
      tap(res => this.saveSession(res)),
      map(() => true),
      catchError(() => of(false))
    );
  }

  updatePassword(currentPassword: string, newPassword: string): Observable<boolean> {
    return this.http.put(`${this.API_URL}/password`, { currentPassword, newPassword }, { withCredentials: true }).pipe(
      map(() => true),
      catchError(() => of(false))
    );
  }

  refreshSession(): Observable<boolean> {
    const storedToken = this.getStoredToken();
    const storedUser = this.getStoredProfile();

    // If we have a stored token, try to validate it via the refresh endpoint
    // Otherwise, if we have stored user info + cookie, try cookie-based refresh
    if (storedToken && storedUser) {
      // We already have credentials in localStorage — restore them into signals
      this.accessToken.set(storedToken);
      this.currentUser.set(storedUser);

      // Try to refresh the token from the backend to get a fresh JWT
      return this.http.post<AuthResponse>(`${this.API_URL}/refresh`, {}, { withCredentials: true }).pipe(
        tap(res => {
          this.saveSession(res);
          this.isLoaded.set(true);
        }),
        map(() => true),
        catchError(() => {
          // Refresh failed but we still have the stored token — keep the session alive
          // The token may still be valid (it will fail on API calls if truly expired)
          this.isLoaded.set(true);
          return of(true);
        })
      );
    }

    // No stored credentials at all — try cookie-only refresh as last resort
    return this.http.post<AuthResponse>(`${this.API_URL}/refresh`, {}, { withCredentials: true }).pipe(
      tap(res => {
        this.saveSession(res);
        this.isLoaded.set(true);
      }),
      map(() => true),
      catchError(() => {
        this.clearSession();
        this.isLoaded.set(true);
        return of(true);
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
      status: 'ACTIVE',
      roles: res.roles || [],
      plan: res.plan || 'BASIC'
    };
    
    this.accessToken.set(res.token);
    this.currentUser.set(user);
    localStorage.setItem(this.STORAGE_TOKEN_KEY, res.token);
    localStorage.setItem(this.STORAGE_USER_KEY, JSON.stringify(user));
  }

  private clearSession(): void {
    this.accessToken.set(null);
    this.currentUser.set(null);
    localStorage.removeItem(this.STORAGE_TOKEN_KEY);
    localStorage.removeItem(this.STORAGE_USER_KEY);
  }
}
