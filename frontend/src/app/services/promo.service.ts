import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment';

export interface PromoCode {
  id?: number;
  code: string;
  discountPercentage: number;
  maxUses?: number;
  currentUses?: number;
  expiresAt?: string;
  active?: boolean;
  createdAt?: string;
}

export interface PromoValidationResult {
  code: string;
  discountPercentage: number;
}

@Injectable({
  providedIn: 'root'
})
export class PromoService {
  private http = inject(HttpClient);
  private apiUrl = environment.apiUrl;

  // --- Admin Endpoints ---
  getAllPromos(): Observable<PromoCode[]> {
    return this.http.get<PromoCode[]>(`${this.apiUrl}/admin/promos`);
  }

  createPromo(promo: Partial<PromoCode>): Observable<PromoCode> {
    return this.http.post<PromoCode>(`${this.apiUrl}/admin/promos`, promo);
  }

  togglePromoStatus(id: number): Observable<PromoCode> {
    return this.http.put<PromoCode>(`${this.apiUrl}/admin/promos/${id}/toggle`, {});
  }

  deletePromo(id: number): Observable<void> {
    return this.http.delete<void>(`${this.apiUrl}/admin/promos/${id}`);
  }

  // --- Public Endpoints ---
  validatePromo(code: string): Observable<PromoValidationResult> {
    return this.http.get<PromoValidationResult>(`${this.apiUrl}/promos/validate?code=${encodeURIComponent(code)}`);
  }
}
