import { ComponentFixture, TestBed } from '@angular/core/testing';
import { AdminUsersComponent } from './admin-users.component';
import { AdminService, AdminUserDto } from '../../../services/admin.service';
import { of } from 'rxjs';
import { FormsModule } from '@angular/forms';

describe('AdminUsersComponent', () => {
  let component: AdminUsersComponent;
  let fixture: ComponentFixture<AdminUsersComponent>;
  let adminServiceSpy: any;

  beforeEach(async () => {
    adminServiceSpy = vi.fn();
    const dummyUsers: AdminUserDto[] = [
      { id: 1, email: 'admin@admin.com', fullName: 'Admin User', status: 'ACTIVE', createdAt: '2023-01-01', role: 'ROLE_ADMIN', plan: 'PRO' }
    ];
    adminServiceSpy.getAllUsers.and.returnValue(of(dummyUsers));

    await TestBed.configureTestingModule({
      imports: [AdminUsersComponent, FormsModule],
      providers: [
        { provide: AdminService, useValue: adminServiceSpy }
      ]
    }).compileComponents();

    fixture = TestBed.createComponent(AdminUsersComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create and load users', () => {
    expect(component).toBeTruthy();
    expect(adminServiceSpy.getAllUsers).toHaveBeenCalled();
    const rows = fixture.nativeElement.querySelectorAll('tbody tr');
    expect(rows.length).toBe(1);
    expect(rows[0].textContent).toContain('admin@admin.com');
  });

  it('should open modal when Reset Password is clicked', () => {
    const buttons = fixture.nativeElement.querySelectorAll('.btn-warning');
    buttons[0].click();
    fixture.detectChanges();
    const modal = fixture.nativeElement.querySelector('.modal-content');
    expect(modal).toBeTruthy();
    // expect(component.selectedUser()?.id).toBe(1);
  });
});
