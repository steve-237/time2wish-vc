import { Injectable, inject, signal } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment';

export interface Pledge {
  id?: number;
  contributorName?: string;
  guestName?: string;
  amount: number;
  message?: string;
  createdAt?: string;
}

export interface Fundraiser {
  id: number;
  giftId: number;
  targetAmount: number;
  currentAmount: number;
  currency: string;
  active: boolean;
  pledges: Pledge[];
}

@Injectable({
  providedIn: 'root'
})
export class FundraiserService {
  private http = inject(HttpClient);
  private apiUrl = environment.apiUrl + '/fundraisers';

  getFundraiser(giftId: number, target?: number): Observable<Fundraiser> {
    const params: any = {};
    if (target) params.target = target;
    return this.http.get<Fundraiser>(`${this.apiUrl}/gift/${giftId}`, { params });
  }

  addPledge(fundraiserId: number, pledge: Partial<Pledge>): Observable<Fundraiser> {
    return this.http.post<Fundraiser>(`${this.apiUrl}/${fundraiserId}/pledges`, pledge);
  }
}
