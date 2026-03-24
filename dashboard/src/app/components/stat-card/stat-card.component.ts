import { Component, Input } from '@angular/core';
import { DecimalPipe } from '@angular/common';

@Component({
  selector: 'app-stat-card',
  standalone: true,
  imports: [DecimalPipe],
  template: `
    <div class="card stat-card">
      <div class="stat-label">{{ label }}</div>
      <div class="stat-value">{{ value | number }}</div>
      @if (subtitle) {
        <div class="stat-subtitle">{{ subtitle }}</div>
      }
    </div>
  `,
  styles: [`
    .stat-card {
      text-align: center;
    }
    .stat-label {
      font-size: 12px;
      text-transform: uppercase;
      letter-spacing: 1px;
      color: var(--text-secondary);
      margin-bottom: 8px;
    }
    .stat-value {
      font-size: 32px;
      font-weight: 700;
      color: var(--primary);
    }
    .stat-subtitle {
      font-size: 13px;
      color: var(--text-secondary);
      margin-top: 4px;
    }
  `],
})
export class StatCardComponent {
  @Input({ required: true }) label!: string;
  @Input({ required: true }) value!: number;
  @Input() subtitle?: string;
}
