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

function makeService(overrides: Partial<{
  getSources: unknown;
  getSummary: unknown;
  getUserStats: unknown;
  getDailyAggregates: unknown;
}> = {}): AnalyticsService {
  const spy = jasmine.createSpyObj<AnalyticsService>('AnalyticsService', [
    'getSources', 'getSummary', 'getUserStats', 'getDailyAggregates',
  ]);
  (spy.getSources as jasmine.Spy).and.returnValue(
    overrides.getSources ?? of(mockSources)
  );
  (spy.getSummary as jasmine.Spy).and.returnValue(
    overrides.getSummary ?? of(mockSummary)
  );
  (spy.getUserStats as jasmine.Spy).and.returnValue(
    overrides.getUserStats ?? of(mockUserStats)
  );
  (spy.getDailyAggregates as jasmine.Spy).and.returnValue(
    overrides.getDailyAggregates ?? of(mockDailyResponse)
  );
  return spy;
}

// Tests use direct class instantiation to avoid Chart.js / TestBed compilation
describe('DashboardComponent', () => {
  it('should create', () => {
    const component = new DashboardComponent(makeService());
    expect(component).toBeTruthy();
  });

  it('should load sources on init', () => {
    const component = new DashboardComponent(makeService());
    component.ngOnInit();
    expect(component.sources).toEqual(['augment']);
  });

  it('should load initial source data on init', () => {
    const component = new DashboardComponent(makeService());
    component.ngOnInit();
    expect(component.summary).toEqual(mockSummary);
    expect(component.users.length).toBe(1);
    expect(component.daily.length).toBe(1);
  });

  it('should set loading false after daily data loads', () => {
    const component = new DashboardComponent(makeService());
    component.ngOnInit();
    expect(component.loading).toBeFalse();
  });

  it('should call loadSource with new source', () => {
    const svc = makeService();
    const component = new DashboardComponent(svc);
    component.loadSource('augment');
    expect((svc.getSummary as jasmine.Spy).calls.count()).toBeGreaterThan(0);
  });

  it('should handle getSources error by falling back to augment', () => {
    const svc = makeService({
      getSources: throwError(() => new Error('net error')),
    });
    const component = new DashboardComponent(svc);
    component.ngOnInit();
    expect(component.sources).toEqual(['augment']);
    expect(component.activeSource).toBe('augment');
  });

  it('should set error message on getSummary failure', () => {
    const svc = makeService({
      getSummary: throwError(() => ({ message: 'summary error' })),
    });
    const component = new DashboardComponent(svc);
    component.ngOnInit();
    expect(component.error).toContain('Failed to load summary');
  });

  it('should set error message on getUserStats failure', () => {
    const svc = makeService({
      getUserStats: throwError(() => ({ message: 'user error' })),
    });
    const component = new DashboardComponent(svc);
    component.ngOnInit();
    expect(component.error).toContain('Failed to load users');
  });

  it('should set error and loading=false on getDailyAggregates failure', () => {
    const svc = makeService({
      getDailyAggregates: throwError(() => ({ message: 'daily error' })),
    });
    const component = new DashboardComponent(svc);
    component.ngOnInit();
    expect(component.error).toContain('Failed to load daily data');
    expect(component.loading).toBeFalse();
  });

  it('should update activeSource when loadSource is called', () => {
    const component = new DashboardComponent(makeService());
    component.loadSource('augment');
    expect(component.activeSource).toBe('augment');
  });
});
