import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment';

export interface AiStat {
  featureType: string;
  count: number;
}

@Injectable({
  providedIn: 'root'
})
export class StatsService {
  private http = inject(HttpClient);
  private apiUrl = environment.apiUrl;

  getAiStats(): Observable<AiStat[]> {
    return this.http.get<AiStat[]>(`${this.apiUrl}/admin/stats/ai`);
  }
}
