import { ComponentFixture, TestBed } from '@angular/core/testing';
import { AdminDashboardComponent } from './admin-dashboard.component';
import { AdminService, StatsResponse } from '../../../services/admin.service';
import { of } from 'rxjs';

describe('AdminDashboardComponent', () => {
  let component: AdminDashboardComponent;
  let fixture: ComponentFixture<AdminDashboardComponent>;
  let adminServiceSpy: any;

  beforeEach(async () => {
    adminServiceSpy = vi.fn();
    const dummyStats: StatsResponse = { totalUsers: 5, totalBirthdays: 20 };
    adminServiceSpy.getStats.and.returnValue(of(dummyStats));

    await TestBed.configureTestingModule({
      imports: [AdminDashboardComponent],
      providers: [
        { provide: AdminService, useValue: adminServiceSpy }
      ]
    }).compileComponents();

    fixture = TestBed.createComponent(AdminDashboardComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('should fetch and display stats', () => {
    const compiled = fixture.nativeElement as HTMLElement;
    expect(adminServiceSpy.getStats).toHaveBeenCalled();
    const values = compiled.querySelectorAll('.stat-value');
    expect(values[0].textContent?.trim()).toBe('5');
    expect(values[1].textContent?.trim()).toBe('20');
  });
});
