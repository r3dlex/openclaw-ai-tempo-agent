import { TopUsersChartComponent } from './top-users-chart.component';
import { UserStats } from '../../models/analytics.model';

const mockUsers: UserStats[] = [
  { email: 'alice@example.com', total_credits: 5000, average_daily: 2500, days_active: 2, last_active: '2025-11-25' },
  { email: 'bob@example.com', total_credits: 3000, average_daily: 1000, days_active: 3, last_active: '2025-11-24' },
];

describe('TopUsersChartComponent (unit)', () => {
  it('should initialize with empty chart data', () => {
    const component = new TopUsersChartComponent();
    expect(component.chartData.labels).toEqual([]);
  });

  it('should build chartData from users on ngOnChanges', () => {
    const component = new TopUsersChartComponent();
    component.users = mockUsers;
    component.ngOnChanges();

    expect(component.chartData.labels).toEqual(['alice', 'bob']);
    const dataset = (component.chartData.datasets as any[])[0];
    expect(dataset.data).toEqual([5000, 3000]);
  });

  it('should only show top 10 users', () => {
    const component = new TopUsersChartComponent();
    component.users = Array.from({ length: 15 }, (_, i) => ({
      email: `user${i}@example.com`,
      total_credits: 1000 - i,
      average_daily: 100,
      days_active: 1,
      last_active: '2025-11-24',
    }));
    component.ngOnChanges();

    expect((component.chartData.labels as string[]).length).toBe(10);
  });

  it('should handle empty users list', () => {
    const component = new TopUsersChartComponent();
    component.users = [];
    component.ngOnChanges();

    expect(component.chartData.labels).toEqual([]);
  });

  it('should strip email domain for labels', () => {
    const component = new TopUsersChartComponent();
    component.users = [{ email: 'charlie@corp.com', total_credits: 999, average_daily: 999, days_active: 1, last_active: '2025-11-25' }];
    component.ngOnChanges();
    expect((component.chartData.labels as string[])[0]).toBe('charlie');
  });
});
