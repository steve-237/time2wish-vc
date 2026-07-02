import { TestBed } from '@angular/core/testing';
import { HttpClientTestingModule, HttpTestingController } from '@angular/common/http/testing';
import { MessagingService, ConversationDto, MessageDto } from './messaging.service';
import { environment } from '../../environments/environment';
import { AuthService } from './auth.service';
import { ContactService } from './contact.service';

describe('MessagingService', () => {
  let service: MessagingService;
  let httpMock: HttpTestingController;

  const mockConversations: ConversationDto[] = [
    { id: 1, type: 'PRIVATE', members: [], unreadCount: 2 },
    { id: 2, type: 'GROUP', name: 'Test Group', members: [], unreadCount: 0 }
  ];

  beforeEach(() => {
    TestBed.configureTestingModule({
      imports: [HttpClientTestingModule],
      providers: [
        MessagingService,
        { provide: AuthService, useValue: { currentUser: () => ({ id: 1 }) } },
        { provide: ContactService, useValue: { getContacts: () => ({ subscribe: () => {} }), getPendingRequests: () => ({ subscribe: () => {} }) } }
      ]
    });
    service = TestBed.inject(MessagingService);
    httpMock = TestBed.inject(HttpTestingController);
  });

  afterEach(() => {
    httpMock.verify();
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });

  it('should load conversations and update signal', () => {
    service.loadConversations().subscribe((convs) => {
      expect(convs).toEqual(mockConversations);
      expect(service.conversations()).toEqual(mockConversations);
    });

    const req = httpMock.expectOne(`${environment.apiUrl}/messaging/conversations`);
    expect(req.request.method).toBe('GET');
    req.flush(mockConversations);
  });

  it('should create private conversation', () => {
    const newConv: ConversationDto = { id: 3, type: 'PRIVATE', members: [], unreadCount: 0 };
    
    service.createPrivateConversation(5).subscribe((conv) => {
      expect(conv).toEqual(newConv);
    });

    const req = httpMock.expectOne(`${environment.apiUrl}/messaging/conversations/private/5`);
    expect(req.request.method).toBe('POST');
    req.flush(newConv);

    // It also triggers loadConversations
    const loadReq = httpMock.expectOne(`${environment.apiUrl}/messaging/conversations`);
    expect(loadReq.request.method).toBe('GET');
    loadReq.flush(mockConversations);
  });

  it('should load messages and update signal', () => {
    const mockMessages: MessageDto[] = [
      { id: 1, conversationId: 1, senderId: 1, senderName: 'User', content: 'Hello', createdAt: new Date().toISOString() }
    ];

    service.loadMessages(1).subscribe((msgs) => {
      expect(msgs).toEqual(mockMessages);
      expect(service.activeMessages()).toEqual(mockMessages);
    });

    const req = httpMock.expectOne(`${environment.apiUrl}/messaging/conversations/1/messages`);
    expect(req.request.method).toBe('GET');
    req.flush(mockMessages);
  });

  it('should get unread count and update signal', () => {
    service.getUnreadCount().subscribe((count) => {
      expect(count).toBe(5);
      expect(service.unreadCount()).toBe(5);
    });

    const req = httpMock.expectOne(`${environment.apiUrl}/messaging/unread-count`);
    expect(req.request.method).toBe('GET');
    req.flush(5);
  });

  it('should mark as read', () => {
    service.markAsRead(1).subscribe();

    const req = httpMock.expectOne(`${environment.apiUrl}/messaging/conversations/1/read`);
    expect(req.request.method).toBe('PUT');
    req.flush(null);

    // It also triggers getUnreadCount
    const countReq = httpMock.expectOne(`${environment.apiUrl}/messaging/unread-count`);
    expect(countReq.request.method).toBe('GET');
    countReq.flush(0);
  });
});
