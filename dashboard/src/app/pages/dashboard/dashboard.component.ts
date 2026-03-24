import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { AnalyticsService } from '../../services/analytics.service';
import { StatCardComponent } from '../../components/stat-card/stat-card.component';
import { UsageChartComponent } from '../../components/usage-chart/usage-chart.component';
import { TopUsersChartComponent } from '../../components/top-users-chart/top-users-chart.component';
import { UserTableComponent } from '../../components/user-table/user-table.component';
import { Summary, UserStats, DailyAggregate } from '../../models/analytics.model';

@Component({
  selector: 'app-dashboard',
  standalone: true,
  imports: [
    CommonModule,
    StatCardComponent,
    UsageChartComponent,
    TopUsersChartComponent,
    UserTableComponent,
  ],
  template: `
    <div class="source-selector">
      @for (src of sources; track src) {
        <button [class.active]="src === activeSource" (click)="loadSource(src)">
          {{ src | titlecase }}
        </button>
      }
    </div>

    @if (summary) {
      <div class="stats-grid">
        <app-stat-card
          label="Total Credits"
          [value]="summary.total_credits"
        />
        <app-stat-card
          label="Total Users"
          [value]="summary.total_users"
          [subtitle]="summary.active_users + ' active'"
        />
        <app-stat-card
          label="Avg Credits / User"
          [value]="summary.average_credits_per_user"
        />
        <app-stat-card
          label="Days Tracked"
          [value]="summary.days_tracked"
        />
      </div>
    }

    @if (daily.length) {
      <app-usage-chart [data]="daily" />
    }

    <div class="charts-row">
      @if (users.length) {
        <app-top-users-chart [users]="users" />
      }
    </div>

    @if (users.length) {
      <app-user-table [users]="users" />
    }

    @if (loading) {
      <div class="loading">Loading analytics...</div>
    }

    @if (error) {
      <div class="error">{{ error }}</div>
    }
  `,
  styles: [`
    .source-selector {
      display: flex;
      gap: 8px;
      margin-bottom: 24px;
    }
    .source-selector button {
      padding: 8px 20px;
      border: 2px solid rgba(255,255,255,0.3);
      border-radius: 8px;
      background: rgba(255,255,255,0.15);
      color: white;
      font-weight: 600;
      cursor: pointer;
      transition: all 0.2s;
    }
    .source-selector button.active {
      background: white;
      color: var(--primary);
      border-color: white;
    }
    .charts-row {
      display: grid;
      grid-template-columns: 1fr;
      gap: 24px;
      margin-bottom: 24px;
    }
    .loading {
      text-align: center;
      color: white;
      padding: 40px;
      font-size: 18px;
    }
    .error {
      text-align: center;
      color: #feb2b2;
      padding: 20px;
      background: rgba(255,0,0,0.1);
      border-radius: 8px;
    }
  `],
})
export class DashboardComponent implements OnInit {
  sources: string[] = [];
  activeSource = 'augment';
  summary: Summary | null = null;
  users: UserStats[] = [];
  daily: DailyAggregate[] = [];
  loading = true;
  error: string | null = null;

  constructor(private analytics: AnalyticsService) {}

  ngOnInit(): void {
    this.analytics.getSources().subscribe({
      next: (res) => {
        this.sources = res.sources;
        if (this.sources.length) {
          this.loadSource(this.sources[0]);
        }
      },
      error: () => {
        this.sources = ['augment'];
        this.loadSource('augment');
      },
    });
  }

  loadSource(source: string): void {
    this.activeSource = source;
    this.loading = true;
    this.error = null;

    this.analytics.getSummary(source).subscribe({
      next: (s) => (this.summary = s),
      error: (e) => (this.error = `Failed to load summary: ${e.message}`),
    });

    this.analytics.getUserStats(source).subscribe({
      next: (r) => (this.users = r.users),
      error: (e) => (this.error = `Failed to load users: ${e.message}`),
    });

    this.analytics.getDailyAggregates(source).subscribe({
      next: (r) => {
        this.daily = r.daily;
        this.loading = false;
      },
      error: (e) => {
        this.error = `Failed to load daily data: ${e.message}`;
        this.loading = false;
      },
    });
  }
}
