import { TestBed } from '@angular/core/testing';
import { StatCardComponent } from './stat-card.component';

describe('StatCardComponent', () => {
  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [StatCardComponent],
    }).compileComponents();
  });

  it('should create', () => {
    const fixture = TestBed.createComponent(StatCardComponent);
    const component = fixture.componentInstance;
    component.label = 'Test Label';
    component.value = 42;
    fixture.detectChanges();
    expect(component).toBeTruthy();
  });

  it('should display the label', () => {
    const fixture = TestBed.createComponent(StatCardComponent);
    const component = fixture.componentInstance;
    component.label = 'Total Credits';
    component.value = 1000;
    fixture.detectChanges();
    const el = fixture.nativeElement as HTMLElement;
    expect(el.querySelector('.stat-label')?.textContent).toContain('Total Credits');
  });

  it('should display the value', () => {
    const fixture = TestBed.createComponent(StatCardComponent);
    const component = fixture.componentInstance;
    component.label = 'Users';
    component.value = 42;
    fixture.detectChanges();
    const el = fixture.nativeElement as HTMLElement;
    expect(el.querySelector('.stat-value')?.textContent).toContain('42');
  });

  it('should display subtitle when provided', () => {
    const fixture = TestBed.createComponent(StatCardComponent);
    const component = fixture.componentInstance;
    component.label = 'Users';
    component.value = 10;
    component.subtitle = '8 active';
    fixture.detectChanges();
    const el = fixture.nativeElement as HTMLElement;
    expect(el.querySelector('.stat-subtitle')?.textContent).toContain('8 active');
  });

  it('should not display subtitle when not provided', () => {
    const fixture = TestBed.createComponent(StatCardComponent);
    const component = fixture.componentInstance;
    component.label = 'Users';
    component.value = 10;
    fixture.detectChanges();
    const el = fixture.nativeElement as HTMLElement;
    expect(el.querySelector('.stat-subtitle')).toBeNull();
  });
});
