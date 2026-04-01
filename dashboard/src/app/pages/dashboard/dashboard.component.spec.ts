import { NO_ERRORS_SCHEMA } from '@angular/core';
import { TestBed, fakeAsync, tick } from '@angular/core/testing';
import { HttpClientTestingModule, HttpTestingController } from '@angular/common/http/testing';
import { RouterTestingModule } from '@angular/router/testing';
import { DashboardComponent } from './dashboard.component';
import { AnalyticsService } from '../../services/analytics.service';
import { of, throwError } from 'rxjs';
import {
  SourcesResponse,
  UserStatsResponse,
  DailyResponse,
  Summary,
} from '../../models/analytics.model';

const mockSummary: Summary = {
  source: 'augment',
  total_credits: 10000,
  total_users: 5,
  active_users: 4,
  days_tracked: 7,
  average_credits_per_user: 2000,
};

const mockUserStats: UserStatsResponse = {
  source: 'augment',
  users: [
    { email: 'alice@example.com', total_credits: 5000, average_daily: 2500, days_active: 2, last_active: '2025-11-25' },
  ],
};

const mockDailyResponse: DailyResponse = {
  source: 'augment',
  daily: [
    { date: '2025-11-24', total_credits: 5000, user_count: 2 },
  ],
};

const mockSources: SourcesResponse = { sources: ['augment'] };

describe('DashboardComponent', () => {
  let analyticsService: jasmine.SpyObj<AnalyticsService>;

  beforeEach(async () => {
    const spy = jasmine.createSpyObj('AnalyticsService', [
      'getSources',
      'getSummary',
      'getUserStats',
      'getDailyAggregates',
    ]);

    spy.getSources.and.returnValue(of(mockSources));
    spy.getSummary.and.returnValue(of(mockSummary));
    spy.getUserStats.and.returnValue(of(mockUserStats));
    spy.getDailyAggregates.and.returnValue(of(mockDailyResponse));

    await TestBed.configureTestingModule({
      imports: [DashboardComponent, HttpClientTestingModule, RouterTestingModule],
      providers: [
        { provide: AnalyticsService, useValue: spy },
      ],
      schemas: [NO_ERRORS_SCHEMA],
    }).compileComponents();

    analyticsService = TestBed.inject(AnalyticsService) as jasmine.SpyObj<AnalyticsService>;
  });

  it('should create', () => {
    const fixture = TestBed.createComponent(DashboardComponent);
    const component = fixture.componentInstance;
    fixture.detectChanges();
    expect(component).toBeTruthy();
  });

  it('should load sources on init', () => {
    const fixture = TestBed.createComponent(DashboardComponent);
    fixture.detectChanges();
    const component = fixture.componentInstance;
    expect(component.sources).toEqual(['augment']);
  });

  it('should load initial source data on init', () => {
    const fixture = TestBed.createComponent(DashboardComponent);
    fixture.detectChanges();
    const component = fixture.componentInstance;
    expect(component.summary).toEqual(mockSummary);
    expect(component.users.length).toBe(1);
    expect(component.daily.length).toBe(1);
  });

  it('should set loading false after daily data loads', () => {
    const fixture = TestBed.createComponent(DashboardComponent);
    fixture.detectChanges();
    const component = fixture.componentInstance;
    expect(component.loading).toBeFalse();
  });

  it('should call loadSource with new source', () => {
    const fixture = TestBed.createComponent(DashboardComponent);
    fixture.detectChanges();
    const component = fixture.componentInstance;

    component.loadSource('augment');
    expect(analyticsService.getSummary).toHaveBeenCalledWith('augment');
  });

  it('should handle getSources error by falling back to augment', () => {
    analyticsService.getSources.and.returnValue(throwError(() => new Error('net error')));
    const fixture = TestBed.createComponent(DashboardComponent);
    fixture.detectChanges();
    const component = fixture.componentInstance;
    expect(component.sources).toEqual(['augment']);
    expect(component.activeSource).toBe('augment');
  });

  it('should set error message on getSummary failure', () => {
    analyticsService.getSummary.and.returnValue(throwError(() => ({ message: 'summary error' })));
    const fixture = TestBed.createComponent(DashboardComponent);
    fixture.detectChanges();
    const component = fixture.componentInstance;
    expect(component.error).toContain('Failed to load summary');
  });

  it('should set error message on getUserStats failure', () => {
    analyticsService.getUserStats.and.returnValue(throwError(() => ({ message: 'user error' })));
    const fixture = TestBed.createComponent(DashboardComponent);
    fixture.detectChanges();
    const component = fixture.componentInstance;
    expect(component.error).toContain('Failed to load users');
  });

  it('should set error and loading=false on getDailyAggregates failure', () => {
    analyticsService.getDailyAggregates.and.returnValue(throwError(() => ({ message: 'daily error' })));
    const fixture = TestBed.createComponent(DashboardComponent);
    fixture.detectChanges();
    const component = fixture.componentInstance;
    expect(component.error).toContain('Failed to load daily data');
    expect(component.loading).toBeFalse();
  });

  it('should update activeSource when loadSource is called', () => {
    const fixture = TestBed.createComponent(DashboardComponent);
    fixture.detectChanges();
    const component = fixture.componentInstance;
    component.loadSource('augment');
    expect(component.activeSource).toBe('augment');
  });
});
