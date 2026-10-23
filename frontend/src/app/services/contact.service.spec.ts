import '@angular/compiler';
import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { createEnvironmentInjector, EnvironmentInjector, runInInjectionContext } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { of } from 'rxjs';
import { ContactService, ContactDto, UserSearchDto } from './contact.service';
import { environment } from '../../environments/environment';

describe('ContactService', () => {
  let service: ContactService;
  let mockHttp: any;
  let injector: EnvironmentInjector;

  const mockContacts: ContactDto[] = [
    { id: 1, userId: 2, fullName: 'John Doe', email: 'john@example.com', status: 'ACCEPTED', createdAt: '2023-01-01' }
  ];

  const mockPending: ContactDto[] = [
    { id: 2, userId: 3, fullName: 'Jane Doe', email: 'jane@example.com', status: 'PENDING', createdAt: '2023-01-02' }
  ];

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

    service = runInInjectionContext(injector, () => new ContactService());
  });

  afterEach(() => {
    vi.clearAllMocks();
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });

  it('should search users and update signal', () => {
    const mockResults: UserSearchDto[] = [
      { id: 4, fullName: 'Test', email: 'test@test.com' }
    ];
    mockHttp.get.mockReturnValue(of(mockResults));

    service.searchUsers('test').subscribe((results) => {
      expect(results).toEqual(mockResults);
      expect(service.searchResults()).toEqual(mockResults);
    });

    expect(mockHttp.get).toHaveBeenCalledWith(`${environment.apiUrl}/contacts/search?q=test`);
  });

  it('should get contacts and update signal', () => {
    mockHttp.get.mockReturnValue(of(mockContacts));

    service.getContacts().subscribe((contacts) => {
      expect(contacts).toEqual(mockContacts);
      expect(service.contacts()).toEqual(mockContacts);
    });

    expect(mockHttp.get).toHaveBeenCalledWith(`${environment.apiUrl}/contacts`);
  });

  it('should get pending requests and update signal', () => {
    mockHttp.get.mockReturnValue(of(mockPending));

    service.getPendingRequests().subscribe((pending) => {
      expect(pending).toEqual(mockPending);
      expect(service.pendingRequests()).toEqual(mockPending);
    });

    expect(mockHttp.get).toHaveBeenCalledWith(`${environment.apiUrl}/contacts/pending`);
  });

  it('should send request', () => {
    mockHttp.post.mockReturnValue(of(mockPending[0]));

    service.sendRequest(5).subscribe((contact) => {
      expect(contact).toEqual(mockPending[0]);
    });

    expect(mockHttp.post).toHaveBeenCalledWith(`${environment.apiUrl}/contacts/request/5`, {});
  });

  it('should accept request and trigger reloads', () => {
    mockHttp.put.mockReturnValue(of(mockContacts[0]));
    mockHttp.get.mockReturnValue(of(mockContacts));

    service.acceptRequest(1).subscribe();

    expect(mockHttp.put).toHaveBeenCalledWith(`${environment.apiUrl}/contacts/1/accept`, {});
  });

  it('should reject request and trigger pending reload', () => {
    mockHttp.put.mockReturnValue(of(mockPending[0]));
    mockHttp.get.mockReturnValue(of([]));

    service.rejectRequest(2).subscribe();

    expect(mockHttp.put).toHaveBeenCalledWith(`${environment.apiUrl}/contacts/2/reject`, {});
  });

  it('should remove contact and trigger contacts reload', () => {
    mockHttp.delete.mockReturnValue(of(null));
    mockHttp.get.mockReturnValue(of([]));

    service.removeContact(1).subscribe();

    expect(mockHttp.delete).toHaveBeenCalledWith(`${environment.apiUrl}/contacts/1`);
  });
});
