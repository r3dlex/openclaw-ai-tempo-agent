import { Component, Input } from '@angular/core';
import { DecimalPipe, DatePipe } from '@angular/common';
import { UserStats } from '../../models/analytics.model';

type SortKey = keyof UserStats;

@Component({
  selector: 'app-user-table',
  standalone: true,
  imports: [DecimalPipe, DatePipe],
  template: `
    <div class="card">
      <h3>User Details</h3>
      <div class="table-wrapper">
        <table>
          <thead>
            <tr>
              <th (click)="sort('email')">User {{ sortIcon('email') }}</th>
              <th (click)="sort('total_credits')">Total Credits {{ sortIcon('total_credits') }}</th>
              <th (click)="sort('average_daily')">Avg Daily {{ sortIcon('average_daily') }}</th>
              <th (click)="sort('days_active')">Days Active {{ sortIcon('days_active') }}</th>
              <th (click)="sort('last_active')">Last Active {{ sortIcon('last_active') }}</th>
            </tr>
          </thead>
          <tbody>
            @for (user of sortedUsers; track user.email) {
              <tr>
                <td>{{ user.email.split('@')[0] }}</td>
                <td>{{ user.total_credits | number }}</td>
                <td>{{ user.average_daily | number:'1.0-0' }}</td>
                <td>{{ user.days_active }}</td>
                <td>{{ user.last_active | date:'mediumDate' }}</td>
              </tr>
            }
          </tbody>
        </table>
      </div>
    </div>
  `,
  styles: [`
    h3 { margin-bottom: 16px; }
    .table-wrapper { overflow-x: auto; }
  `],
})
export class UserTableComponent {
  @Input({ required: true }) users: UserStats[] = [];

  sortKey: SortKey = 'total_credits';
  sortDir: 'asc' | 'desc' = 'desc';

  get sortedUsers(): UserStats[] {
    return [...this.users].sort((a, b) => {
      const va = a[this.sortKey];
      const vb = b[this.sortKey];
      const cmp = va < vb ? -1 : va > vb ? 1 : 0;
      return this.sortDir === 'asc' ? cmp : -cmp;
    });
  }

  sort(key: SortKey): void {
    if (this.sortKey === key) {
      this.sortDir = this.sortDir === 'asc' ? 'desc' : 'asc';
    } else {
      this.sortKey = key;
      this.sortDir = 'desc';
    }
  }

  sortIcon(key: SortKey): string {
    if (this.sortKey !== key) return '';
    return this.sortDir === 'asc' ? '\u25B2' : '\u25BC';
  }
}
