import { Injectable, inject, signal } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, tap } from 'rxjs';
import { environment } from '../../environments/environment';
import { Client } from '@stomp/stompjs';
import SockJS from 'sockjs-client';

import { AuthService } from './auth.service';
import { ContactService } from './contact.service';

export interface ConversationMemberDto { userId: number; fullName: string; avatarUrl?: string; role: string; joinedAt: string; }
export interface ConversationDto { id: number; name?: string; type: string; birthdayId?: number; members: ConversationMemberDto[]; lastMessage?: string; lastMessageAt?: string; unreadCount: number; }
export interface MessageDto { id: number; conversationId: number; senderId: number; senderName: string; senderAvatar?: string; content: string; createdAt: string; }

@Injectable({
  providedIn: 'root'
})
export class MessagingService {
  private http = inject(HttpClient);
  private authService = inject(AuthService);
  private contactService = inject(ContactService);
  private apiUrl = `${environment.apiUrl}/messaging`;
  private stompClient: Client | null = null;
  private currentSubscription: any = null;

  conversations = signal<ConversationDto[]>([]);
  activeMessages = signal<MessageDto[]>([]);
  activeConversationId = signal<number | null>(null);
  unreadCount = signal<number>(0);
  isConnected = signal<boolean>(false);

  loadConversations(): Observable<ConversationDto[]> {
    return this.http.get<ConversationDto[]>(`${this.apiUrl}/conversations`).pipe(
      tap(convs => this.conversations.set(convs))
    );
  }

  createPrivateConversation(contactUserId: number): Observable<ConversationDto> {
    return this.http.post<ConversationDto>(`${this.apiUrl}/conversations/private/${contactUserId}`, {}).pipe(
      tap(() => this.loadConversations().subscribe())
    );
  }

  createGroupConversation(name: string, memberIds: number[]): Observable<ConversationDto> {
    return this.http.post<ConversationDto>(`${this.apiUrl}/conversations/group`, { name, memberIds }).pipe(
      tap(() => this.loadConversations().subscribe())
    );
  }

  createBirthdayGroup(birthdayId: number, memberIds: number[]): Observable<ConversationDto> {
    return this.http.post<ConversationDto>(`${this.apiUrl}/conversations/birthday/${birthdayId}`, { name: '', memberIds }).pipe(
      tap(() => this.loadConversations().subscribe())
    );
  }

  loadMessages(conversationId: number): Observable<MessageDto[]> {
    return this.http.get<MessageDto[]>(`${this.apiUrl}/conversations/${conversationId}/messages`).pipe(
      tap(msgs => this.activeMessages.set(msgs))
    );
  }

  markAsRead(conversationId: number): Observable<void> {
    return this.http.put<void>(`${this.apiUrl}/conversations/${conversationId}/read`, {}).pipe(
      tap(() => this.getUnreadCount().subscribe())
    );
  }

  getUnreadCount(): Observable<number> {
    return this.http.get<number>(`${this.apiUrl}/unread-count`).pipe(
      tap(count => this.unreadCount.set(count))
    );
  }

  addMember(conversationId: number, userId: number): Observable<ConversationDto> {
    return this.http.post<ConversationDto>(`${this.apiUrl}/conversations/${conversationId}/members/${userId}`, {}).pipe(
      tap(() => this.loadConversations().subscribe())
    );
  }

  removeMember(conversationId: number, userId: number): Observable<void> {
    return this.http.delete<void>(`${this.apiUrl}/conversations/${conversationId}/members/${userId}`).pipe(
      tap(() => this.loadConversations().subscribe())
    );
  }

  connect(token: string): void {
    if (this.isConnected()) return;

    this.stompClient = new Client({
      webSocketFactory: () => new SockJS('/ws'),
      connectHeaders: { Authorization: `Bearer ${token}` },
      reconnectDelay: 5000,
      onConnect: () => {
        this.isConnected.set(true);
        // Subscribe to global notifications for contacts
        const user = this.authService.currentUser();
        if (user) {
          this.stompClient?.subscribe(`/topic/user.${user.id}.contacts`, () => {
            this.contactService.getContacts().subscribe();
            this.contactService.getPendingRequests().subscribe();
          });
        }
      },
      onDisconnect: () => {
        this.isConnected.set(false);
      }
    });

    this.stompClient.activate();
  }

  disconnect(): void {
    if (this.stompClient) {
      this.stompClient.deactivate();
      this.isConnected.set(false);
    }
  }

  subscribeToConversation(conversationId: number): void {
    if (this.currentSubscription) {
      this.currentSubscription.unsubscribe();
    }

    if (this.stompClient && this.isConnected()) {
      this.currentSubscription = this.stompClient.subscribe(`/topic/conversation/${conversationId}`, (message) => {
        if (message.body) {
          const msgDto: MessageDto = JSON.parse(message.body);
          if (this.activeConversationId() === conversationId) {
            this.activeMessages.update(msgs => [...msgs, msgDto]);
            this.markAsRead(conversationId).subscribe();
          } else {
            this.getUnreadCount().subscribe();
          }
          this.loadConversations().subscribe();
        }
      });
    }
  }

  sendMessage(conversationId: number, content: string): void {
    if (this.stompClient && this.isConnected()) {
      this.stompClient.publish({
        destination: '/app/chat.sendMessage',
        body: JSON.stringify({ conversationId, content })
      });
    }
  }
}
