import { TestBed, ComponentFixture } from '@angular/core/testing';
import { UsageChartComponent } from './usage-chart.component';
import { DailyAggregate } from '../../models/analytics.model';
import { MockModule } from 'ng-mocks';
import { BaseChartDirective } from 'ng2-charts';

const mockData: DailyAggregate[] = [
  { date: '2025-11-24', total_credits: 5000, user_count: 2 },
  { date: '2025-11-25', total_credits: 8000, user_count: 3 },
];

// Minimal test without ng2-charts rendering (requires canvas)
describe('UsageChartComponent (unit)', () => {
  it('should update chartData from input on ngOnChanges', () => {
    const component = new UsageChartComponent();
    component.data = mockData;
    component.ngOnChanges();

    expect(component.chartData.labels).toEqual(['11-24', '11-25']);
    const dataset = (component.chartData.datasets as any[])[0];
    expect(dataset.data).toEqual([5000, 8000]);
  });

  it('should default chart type to line', () => {
    const component = new UsageChartComponent();
    expect(component.chartType).toBe('line');
  });

  it('should switch chartType and rebuild on updateChart', () => {
    const component = new UsageChartComponent();
    component.data = mockData;
    component.chartType = 'bar';
    component.updateChart();
    expect(component.chartType).toBe('bar');
    expect((component.chartData.labels as string[]).length).toBe(2);
  });

  it('should handle empty data', () => {
    const component = new UsageChartComponent();
    component.data = [];
    component.ngOnChanges();
    expect(component.chartData.labels).toEqual([]);
    expect((component.chartData.datasets as any[])[0].data).toEqual([]);
  });
});
