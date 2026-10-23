import '@angular/compiler';
import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { createEnvironmentInjector, EnvironmentInjector, runInInjectionContext } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { of } from 'rxjs';
import { AdminService, StatsResponse, AdminUserDto } from './admin.service';
import { environment } from '../../environments/environment';

describe('AdminService', () => {
  let service: AdminService;
  let mockHttp: any;
  let injector: EnvironmentInjector;

  const apiUrl = environment.apiUrl + '/admin';

  beforeEach(() => {
    mockHttp = {
      get: vi.fn(),
      post: vi.fn(),
      put: vi.fn(),
      delete: vi.fn()
    };

    injector = createEnvironmentInjector([
      { provide: HttpClient, useValue: mockHttp }
    ]);

    service = runInInjectionContext(injector, () => new AdminService());
  });

  afterEach(() => {
    vi.clearAllMocks();
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });

  it('should fetch stats', () => {
    const dummyStats: StatsResponse = { totalUsers: 10, totalBirthdays: 100 };
    mockHttp.get.mockReturnValue(of(dummyStats));

    service.getStats().subscribe(stats => {
      expect(stats.totalUsers).toBe(10);
      expect(stats.totalBirthdays).toBe(100);
    });

    expect(mockHttp.get).toHaveBeenCalledWith(`${apiUrl}/stats`);
  });

  it('should fetch all users', () => {
    const dummyUsers: AdminUserDto[] = [
      { id: 1, email: 'test@test.com', fullName: 'Test User', status: 'ACTIVE', createdAt: '2023-01-01', role: 'ROLE_USER', plan: 'BASIC' }
    ];
    mockHttp.get.mockReturnValue(of(dummyUsers));

    service.getAllUsers().subscribe(users => {
      expect(users.length).toBe(1);
      expect(users[0].email).toBe('test@test.com');
    });

    expect(mockHttp.get).toHaveBeenCalledWith(`${apiUrl}/users`);
  });

  it('should delete a user', () => {
    mockHttp.delete.mockReturnValue(of(null));

    service.deleteUser(1).subscribe(res => {
      expect(res).toBeNull();
    });

    expect(mockHttp.delete).toHaveBeenCalledWith(`${apiUrl}/users/1`);
  });
});
