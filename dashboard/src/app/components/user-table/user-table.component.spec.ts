import { TestBed } from '@angular/core/testing';
import { UserTableComponent } from './user-table.component';
import { UserStats } from '../../models/analytics.model';

const mockUsers: UserStats[] = [
  { email: 'alice@example.com', total_credits: 5000, average_daily: 2500, days_active: 2, last_active: '2025-11-25' },
  { email: 'bob@example.com', total_credits: 3000, average_daily: 1000, days_active: 3, last_active: '2025-11-24' },
  { email: 'charlie@example.com', total_credits: 8000, average_daily: 4000, days_active: 2, last_active: '2025-11-26' },
];

describe('UserTableComponent', () => {
  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [UserTableComponent],
    }).compileComponents();
  });

  it('should create', () => {
    const fixture = TestBed.createComponent(UserTableComponent);
    const component = fixture.componentInstance;
    component.users = mockUsers;
    fixture.detectChanges();
    expect(component).toBeTruthy();
  });

  it('should display users sorted by total_credits descending by default', () => {
    const fixture = TestBed.createComponent(UserTableComponent);
    const component = fixture.componentInstance;
    component.users = mockUsers;
    fixture.detectChanges();
    const sorted = component.sortedUsers;
    expect(sorted[0].email).toBe('charlie@example.com');
    expect(sorted[1].email).toBe('alice@example.com');
    expect(sorted[2].email).toBe('bob@example.com');
  });

  it('should toggle sort direction when same key is clicked', () => {
    const fixture = TestBed.createComponent(UserTableComponent);
    const component = fixture.componentInstance;
    component.users = mockUsers;
    fixture.detectChanges();

    // Default is desc
    expect(component.sortDir).toBe('desc');
    // Click same key to toggle
    component.sort('total_credits');
    expect(component.sortDir).toBe('asc');
    component.sort('total_credits');
    expect(component.sortDir).toBe('desc');
  });

  it('should change sort key and default to desc when different key clicked', () => {
    const fixture = TestBed.createComponent(UserTableComponent);
    const component = fixture.componentInstance;
    component.users = mockUsers;
    fixture.detectChanges();

    component.sort('email');
    expect(component.sortKey).toBe('email');
    expect(component.sortDir).toBe('desc');
  });

  it('should return empty string for sortIcon when key is not active', () => {
    const fixture = TestBed.createComponent(UserTableComponent);
    const component = fixture.componentInstance;
    component.users = mockUsers;
    fixture.detectChanges();

    expect(component.sortIcon('email')).toBe('');
  });

  it('should return descending arrow for active desc sort key', () => {
    const fixture = TestBed.createComponent(UserTableComponent);
    const component = fixture.componentInstance;
    component.users = mockUsers;
    fixture.detectChanges();

    // Default sort is total_credits desc
    expect(component.sortIcon('total_credits')).toBe('▼');
  });

  it('should return ascending arrow for active asc sort key', () => {
    const fixture = TestBed.createComponent(UserTableComponent);
    const component = fixture.componentInstance;
    component.users = mockUsers;
    fixture.detectChanges();

    component.sortDir = 'asc';
    expect(component.sortIcon('total_credits')).toBe('▲');
  });

  it('should sort strings correctly', () => {
    const fixture = TestBed.createComponent(UserTableComponent);
    const component = fixture.componentInstance;
    component.users = mockUsers;
    component.sortKey = 'email';
    component.sortDir = 'asc';
    fixture.detectChanges();

    const sorted = component.sortedUsers;
    expect(sorted[0].email).toBe('alice@example.com');
  });

  it('should render table rows', () => {
    const fixture = TestBed.createComponent(UserTableComponent);
    const component = fixture.componentInstance;
    component.users = mockUsers;
    fixture.detectChanges();
    const rows = (fixture.nativeElement as HTMLElement).querySelectorAll('tbody tr');
    expect(rows.length).toBe(3);
  });
});
