import { Component, Input, OnChanges } from '@angular/core';
import { BaseChartDirective } from 'ng2-charts';
import { ChartConfiguration } from 'chart.js';
import { UserStats } from '../../models/analytics.model';

@Component({
  selector: 'app-top-users-chart',
  standalone: true,
  imports: [BaseChartDirective],
  template: `
    <div class="card chart-container">
      <h3>Top 10 Users by Credits</h3>
      <canvas baseChart
        [data]="chartData"
        [options]="chartOptions"
        type="bar">
      </canvas>
    </div>
  `,
  styles: [`h3 { margin-bottom: 16px; }`],
})
export class TopUsersChartComponent implements OnChanges {
  @Input({ required: true }) users: UserStats[] = [];

  chartData: ChartConfiguration<'bar'>['data'] = { labels: [], datasets: [] };

  chartOptions: ChartConfiguration<'bar'>['options'] = {
    indexAxis: 'y',
    responsive: true,
    plugins: {
      legend: { display: false },
    },
  };

  ngOnChanges(): void {
    const top = this.users.slice(0, 10);
    this.chartData = {
      labels: top.map(u => u.email.split('@')[0]),
      datasets: [
        {
          data: top.map(u => u.total_credits),
          label: 'Total Credits',
          backgroundColor: '#764ba2',
        },
      ],
    };
  }
}
