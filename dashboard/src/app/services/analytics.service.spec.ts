import { TestBed } from '@angular/core/testing';
import { HttpClientTestingModule, HttpTestingController } from '@angular/common/http/testing';
import { AnalyticsService } from './analytics.service';
import {
  SourcesResponse,
  UserStatsResponse,
  DailyResponse,
  Summary,
} from '../models/analytics.model';

describe('AnalyticsService', () => {
  let service: AnalyticsService;
  let httpMock: HttpTestingController;

  beforeEach(() => {
    TestBed.configureTestingModule({
      imports: [HttpClientTestingModule],
      providers: [AnalyticsService],
    });
    service = TestBed.inject(AnalyticsService);
    httpMock = TestBed.inject(HttpTestingController);
  });

  afterEach(() => {
    httpMock.verify();
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });

  describe('getSources', () => {
    it('should GET /api/v1/analytics/sources', () => {
      const mockResponse: SourcesResponse = { sources: ['augment'] };
      service.getSources().subscribe(res => {
        expect(res.sources).toEqual(['augment']);
      });
      const req = httpMock.expectOne('/api/v1/analytics/sources');
      expect(req.request.method).toBe('GET');
      req.flush(mockResponse);
    });
  });

  describe('getUserStats', () => {
    it('should GET /api/v1/analytics/augment/users', () => {
      const mockResponse: UserStatsResponse = {
        source: 'augment',
        users: [
          {
            email: 'alice@example.com',
            total_credits: 1000,
            average_daily: 500,
            days_active: 2,
            last_active: '2025-11-25',
          },
        ],
      };
      service.getUserStats('augment').subscribe(res => {
        expect(res.source).toBe('augment');
        expect(res.users.length).toBe(1);
        expect(res.users[0].email).toBe('alice@example.com');
      });
      const req = httpMock.expectOne('/api/v1/analytics/augment/users');
      expect(req.request.method).toBe('GET');
      req.flush(mockResponse);
    });
  });

  describe('getDailyAggregates', () => {
    it('should GET /api/v1/analytics/augment/daily', () => {
      const mockResponse: DailyResponse = {
        source: 'augment',
        daily: [
          { date: '2025-11-24', total_credits: 5000, user_count: 3 },
        ],
      };
      service.getDailyAggregates('augment').subscribe(res => {
        expect(res.daily.length).toBe(1);
        expect(res.daily[0].total_credits).toBe(5000);
      });
      const req = httpMock.expectOne('/api/v1/analytics/augment/daily');
      expect(req.request.method).toBe('GET');
      req.flush(mockResponse);
    });
  });

  describe('getSummary', () => {
    it('should GET /api/v1/analytics/augment/summary', () => {
      const mockSummary: Summary = {
        source: 'augment',
        total_credits: 10000,
        total_users: 5,
        active_users: 4,
        days_tracked: 7,
        average_credits_per_user: 2000,
      };
      service.getSummary('augment').subscribe(res => {
        expect(res.total_credits).toBe(10000);
        expect(res.source).toBe('augment');
      });
      const req = httpMock.expectOne('/api/v1/analytics/augment/summary');
      expect(req.request.method).toBe('GET');
      req.flush(mockSummary);
    });
  });
});
