import { Component, Input, OnChanges } from '@angular/core';
import { BaseChartDirective } from 'ng2-charts';
import { ChartConfiguration } from 'chart.js';
import { DailyAggregate } from '../../models/analytics.model';

@Component({
  selector: 'app-usage-chart',
  standalone: true,
  imports: [BaseChartDirective],
  template: `
    <div class="card chart-container">
      <h3>Daily Usage Trend</h3>
      <div class="chart-toggle">
        <button [class.active]="chartType === 'line'" (click)="chartType = 'line'; updateChart()">Line</button>
        <button [class.active]="chartType === 'bar'" (click)="chartType = 'bar'; updateChart()">Bar</button>
      </div>
      <canvas baseChart
        [data]="chartData"
        [options]="chartOptions"
        [type]="chartType">
      </canvas>
    </div>
  `,
  styles: [`
    h3 { margin-bottom: 16px; }
    .chart-toggle {
      display: flex;
      gap: 8px;
      margin-bottom: 16px;
    }
    .chart-toggle button {
      padding: 6px 16px;
      border: 1px solid var(--border);
      border-radius: 6px;
      background: white;
      cursor: pointer;
      font-size: 13px;
    }
    .chart-toggle button.active {
      background: var(--primary);
      color: white;
      border-color: var(--primary);
    }
  `],
})
export class UsageChartComponent implements OnChanges {
  @Input({ required: true }) data: DailyAggregate[] = [];

  chartType: 'line' | 'bar' = 'line';

  chartData: ChartConfiguration['data'] = { labels: [], datasets: [] };

  chartOptions: ChartConfiguration['options'] = {
    responsive: true,
    plugins: {
      legend: { display: false },
    },
    scales: {
      y: { beginAtZero: true },
    },
  };

  ngOnChanges(): void {
    this.updateChart();
  }

  updateChart(): void {
    this.chartData = {
      labels: this.data.map(d => d.date.slice(5)),
      datasets: [
        {
          data: this.data.map(d => d.total_credits),
          label: 'Credits',
          borderColor: '#667eea',
          backgroundColor: 'rgba(102, 126, 234, 0.3)',
          fill: true,
          tension: 0.3,
        },
      ],
    };
  }
}
