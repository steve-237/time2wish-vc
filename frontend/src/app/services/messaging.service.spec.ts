import '@angular/compiler';
import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { createEnvironmentInjector, EnvironmentInjector, runInInjectionContext } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { of } from 'rxjs';
import { MessagingService, ConversationDto, MessageDto } from './messaging.service';
import { environment } from '../../environments/environment';
import { AuthService } from './auth.service';
import { ContactService } from './contact.service';

describe('MessagingService', () => {
  let service: MessagingService;
  let mockHttp: any;
  let injector: EnvironmentInjector;

  const mockConversations: ConversationDto[] = [
    { id: 1, type: 'PRIVATE', members: [], unreadCount: 2 },
    { id: 2, type: 'GROUP', name: 'Test Group', members: [], unreadCount: 0 }
  ];

  beforeEach(() => {
    mockHttp = {
      get: vi.fn(),
      post: vi.fn(),
      put: vi.fn(),
      delete: vi.fn()
    };

    injector = createEnvironmentInjector([
      { provide: HttpClient, useValue: mockHttp },
      { provide: AuthService, useValue: { currentUser: () => ({ id: 1 }) } },
      { provide: ContactService, useValue: { getContacts: () => of([]), getPendingRequests: () => of([]) } }
    ]);

    service = runInInjectionContext(injector, () => new MessagingService());
  });

  afterEach(() => {
    vi.clearAllMocks();
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });

  it('should load conversations and update signal', () => {
    mockHttp.get.mockReturnValue(of(mockConversations));

    service.loadConversations().subscribe((convs) => {
      expect(convs).toEqual(mockConversations);
      expect(service.conversations()).toEqual(mockConversations);
    });

    expect(mockHttp.get).toHaveBeenCalledWith(`${environment.apiUrl}/messaging/conversations`);
  });

  it('should create private conversation', () => {
    const newConv: ConversationDto = { id: 3, type: 'PRIVATE', members: [], unreadCount: 0 };
    mockHttp.post.mockReturnValue(of(newConv));
    mockHttp.get.mockReturnValue(of(mockConversations));

    service.createPrivateConversation(5).subscribe((conv) => {
      expect(conv).toEqual(newConv);
    });

    expect(mockHttp.post).toHaveBeenCalledWith(`${environment.apiUrl}/messaging/conversations/private/5`, {});
  });

  it('should load messages and update signal', () => {
    const mockMessages: MessageDto[] = [
      { id: 1, conversationId: 1, senderId: 1, senderName: 'User', content: 'Hello', createdAt: new Date().toISOString() }
    ];
    mockHttp.get.mockReturnValue(of(mockMessages));

    service.loadMessages(1).subscribe((msgs) => {
      expect(msgs).toEqual(mockMessages);
      expect(service.activeMessages()).toEqual(mockMessages);
    });

    expect(mockHttp.get).toHaveBeenCalledWith(`${environment.apiUrl}/messaging/conversations/1/messages`);
  });

  it('should get unread count and update signal', () => {
    mockHttp.get.mockReturnValue(of(5));

    service.getUnreadCount().subscribe((count) => {
      expect(count).toBe(5);
      expect(service.unreadCount()).toBe(5);
    });

    expect(mockHttp.get).toHaveBeenCalledWith(`${environment.apiUrl}/messaging/unread-count`);
  });

  it('should mark as read', () => {
    mockHttp.put.mockReturnValue(of(null));
    mockHttp.get.mockReturnValue(of(0));

    service.markAsRead(1).subscribe();

    expect(mockHttp.put).toHaveBeenCalledWith(`${environment.apiUrl}/messaging/conversations/1/read`, {});
  });
});
