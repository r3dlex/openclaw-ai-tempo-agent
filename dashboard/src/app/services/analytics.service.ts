import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import {
  SourcesResponse,
  UserStatsResponse,
  DailyResponse,
  Summary,
} from '../models/analytics.model';

@Injectable({ providedIn: 'root' })
export class AnalyticsService {
  private readonly baseUrl = '/api/v1/analytics';

  constructor(private http: HttpClient) {}

  getSources(): Observable<SourcesResponse> {
    return this.http.get<SourcesResponse>(`${this.baseUrl}/sources`);
  }

  getUserStats(source: string): Observable<UserStatsResponse> {
    return this.http.get<UserStatsResponse>(`${this.baseUrl}/${source}/users`);
  }

  getDailyAggregates(source: string): Observable<DailyResponse> {
    return this.http.get<DailyResponse>(`${this.baseUrl}/${source}/daily`);
  }

  getSummary(source: string): Observable<Summary> {
    return this.http.get<Summary>(`${this.baseUrl}/${source}/summary`);
  }
}
