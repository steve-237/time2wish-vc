import { TestBed } from '@angular/core/testing';
import { HttpClientTestingModule, HttpTestingController } from '@angular/common/http/testing';
import { AdminService, StatsResponse, AdminUserDto } from './admin.service';


describe('AdminService', () => {
  let service: AdminService;
  let httpMock: HttpTestingController;

  beforeEach(() => {
    TestBed.configureTestingModule({
      imports: [HttpClientTestingModule],
      providers: [AdminService]
    });
    service = TestBed.inject(AdminService);
    httpMock = TestBed.inject(HttpTestingController);
  });

  afterEach(() => {
    httpMock.verify();
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });

  it('should fetch stats', () => {
    const dummyStats: StatsResponse = { totalUsers: 10, totalBirthdays: 100 };

    service.getStats().subscribe(stats => {
      expect(stats.totalUsers).toBe(10);
      expect(stats.totalBirthdays).toBe(100);
    });

    const req = httpMock.expectOne(`http://localhost:8081/api/admin/stats`);
    expect(req.request.method).toBe('GET');
    req.flush(dummyStats);
  });

  it('should fetch all users', () => {
    const dummyUsers: AdminUserDto[] = [
      { id: 1, email: 'test@test.com', fullName: 'Test User', status: 'ACTIVE', createdAt: '2023-01-01', role: 'ROLE_USER', plan: 'BASIC' }
    ];

    service.getAllUsers().subscribe(users => {
      expect(users.length).toBe(1);
      expect(users[0].email).toBe('test@test.com');
    });

    const req = httpMock.expectOne(`http://localhost:8081/api/admin/users`);
    expect(req.request.method).toBe('GET');
    req.flush(dummyUsers);
  });

  it('should delete a user', () => {
    service.deleteUser(1).subscribe(res => {
      expect(res).toBeNull();
    });

    const req = httpMock.expectOne(`http://localhost:8081/api/admin/users/1`);
    expect(req.request.method).toBe('DELETE');
    req.flush(null);
  });


});
