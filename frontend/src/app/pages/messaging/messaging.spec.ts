import { ComponentFixture, TestBed } from '@angular/core/testing';
import { MessagingPage } from './messaging';
import { HttpClientTestingModule } from '@angular/common/http/testing';
import { RouterTestingModule } from '@angular/router/testing';
import { MessagingService } from '../../services/messaging.service';
import { ContactService } from '../../services/contact.service';
import { AuthService } from '../../services/auth.service';
import { TranslationService } from '../../services/translation.service';
import { ToastService } from '../../services/toast.service';
import { of } from 'rxjs';

describe('MessagingPage Component', () => {
  let component: MessagingPage;
  let fixture: ComponentFixture<MessagingPage>;

  beforeEach(async () => {
    const mockMessagingService = {
      conversations: () => [],
      activeMessages: () => [],
      activeConversationId: () => null,
      unreadCount: () => 0,
      isConnected: () => true,
      loadConversations: () => of([]),
      loadMessages: () => of([]),
      markAsRead: () => of(null),
      sendMessage: vi.fn(),
      subscribeToConversation: vi.fn()
    };

    const mockContactService = {
      contacts: () => [],
      getContacts: () => ({ subscribe: () => {} })
    };

    const mockAuthService = {
      currentUser: () => ({ id: 1, fullName: 'Test' }),
      accessToken: () => 'token'
    };

    const mockTranslationService = {
      t: (key: string) => key
    };

    const mockToastService = {
      success: vi.fn(),
      error: vi.fn()
    };

    await TestBed.configureTestingModule({
      imports: [MessagingPage, HttpClientTestingModule, RouterTestingModule],
      providers: [
        { provide: MessagingService, useValue: mockMessagingService },
        { provide: ContactService, useValue: mockContactService },
        { provide: AuthService, useValue: mockAuthService },
        { provide: TranslationService, useValue: mockTranslationService },
        { provide: ToastService, useValue: mockToastService }
      ]
    }).compileComponents();

    fixture = TestBed.createComponent(MessagingPage);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create the messaging component', () => {
    expect(component).toBeTruthy();
  });
});
