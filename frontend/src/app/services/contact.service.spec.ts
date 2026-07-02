import { TestBed } from '@angular/core/testing';
import { HttpClientTestingModule, HttpTestingController } from '@angular/common/http/testing';
import { ContactService, ContactDto, UserSearchDto } from './contact.service';
import { environment } from '../../environments/environment';

describe('ContactService', () => {
  let service: ContactService;
  let httpMock: HttpTestingController;

  const mockContacts: ContactDto[] = [
    { id: 1, userId: 2, fullName: 'John Doe', email: 'john@example.com', status: 'ACCEPTED', createdAt: '2023-01-01' }
  ];

  const mockPending: ContactDto[] = [
    { id: 2, userId: 3, fullName: 'Jane Doe', email: 'jane@example.com', status: 'PENDING', createdAt: '2023-01-02' }
  ];

  beforeEach(() => {
    TestBed.configureTestingModule({
      imports: [HttpClientTestingModule],
      providers: [ContactService]
    });
    service = TestBed.inject(ContactService);
    httpMock = TestBed.inject(HttpTestingController);
  });

  afterEach(() => {
    httpMock.verify();
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });

  it('should search users and update signal', () => {
    const mockResults: UserSearchDto[] = [
      { id: 4, fullName: 'Test', email: 'test@test.com' }
    ];

    service.searchUsers('test').subscribe((results) => {
      expect(results).toEqual(mockResults);
      expect(service.searchResults()).toEqual(mockResults);
    });

    const req = httpMock.expectOne(`${environment.apiUrl}/contacts/search?q=test`);
    expect(req.request.method).toBe('GET');
    req.flush(mockResults);
  });

  it('should get contacts and update signal', () => {
    service.getContacts().subscribe((contacts) => {
      expect(contacts).toEqual(mockContacts);
      expect(service.contacts()).toEqual(mockContacts);
    });

    const req = httpMock.expectOne(`${environment.apiUrl}/contacts`);
    expect(req.request.method).toBe('GET');
    req.flush(mockContacts);
  });

  it('should get pending requests and update signal', () => {
    service.getPendingRequests().subscribe((pending) => {
      expect(pending).toEqual(mockPending);
      expect(service.pendingRequests()).toEqual(mockPending);
    });

    const req = httpMock.expectOne(`${environment.apiUrl}/contacts/pending`);
    expect(req.request.method).toBe('GET');
    req.flush(mockPending);
  });

  it('should send request', () => {
    service.sendRequest(5).subscribe((contact) => {
      expect(contact).toEqual(mockPending[0]);
    });

    const req = httpMock.expectOne(`${environment.apiUrl}/contacts/request/5`);
    expect(req.request.method).toBe('POST');
    req.flush(mockPending[0]);
  });

  it('should accept request and trigger reloads', () => {
    service.acceptRequest(1).subscribe();

    const req = httpMock.expectOne(`${environment.apiUrl}/contacts/1/accept`);
    expect(req.request.method).toBe('PUT');
    req.flush(mockContacts[0]);

    const reqContacts = httpMock.expectOne(`${environment.apiUrl}/contacts`);
    expect(reqContacts.request.method).toBe('GET');
    reqContacts.flush(mockContacts);

    const reqPending = httpMock.expectOne(`${environment.apiUrl}/contacts/pending`);
    expect(reqPending.request.method).toBe('GET');
    reqPending.flush([]);
  });

  it('should reject request and trigger pending reload', () => {
    service.rejectRequest(2).subscribe();

    const req = httpMock.expectOne(`${environment.apiUrl}/contacts/2/reject`);
    expect(req.request.method).toBe('PUT');
    req.flush(mockPending[0]);

    const reqPending = httpMock.expectOne(`${environment.apiUrl}/contacts/pending`);
    expect(reqPending.request.method).toBe('GET');
    reqPending.flush([]);
  });

  it('should remove contact and trigger contacts reload', () => {
    service.removeContact(1).subscribe();

    const req = httpMock.expectOne(`${environment.apiUrl}/contacts/1`);
    expect(req.request.method).toBe('DELETE');
    req.flush(null);

    const reqContacts = httpMock.expectOne(`${environment.apiUrl}/contacts`);
    expect(reqContacts.request.method).toBe('GET');
    reqContacts.flush([]);
  });
});
