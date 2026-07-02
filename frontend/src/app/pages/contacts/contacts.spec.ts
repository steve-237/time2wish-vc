import { ComponentFixture, TestBed } from '@angular/core/testing';
import { ContactsPage } from './contacts';
import { HttpClientTestingModule } from '@angular/common/http/testing';
import { RouterTestingModule } from '@angular/router/testing';
import { ContactService } from '../../services/contact.service';
import { TranslationService } from '../../services/translation.service';
import { ToastService } from '../../services/toast.service';

describe('ContactsPage Component', () => {
  let component: ContactsPage;
  let fixture: ComponentFixture<ContactsPage>;

  beforeEach(async () => {
    const mockContactService = {
      contacts: () => [],
      pendingRequests: () => [],
      searchResults: () => [],
      getContacts: () => ({ subscribe: () => {} }),
      getPendingRequests: () => ({ subscribe: () => {} }),
      searchUsers: () => ({ subscribe: () => {} }),
      sendRequest: () => ({ subscribe: () => {} }),
      acceptRequest: () => ({ subscribe: () => {} }),
      rejectRequest: () => ({ subscribe: () => {} }),
      removeContact: () => ({ subscribe: () => {} })
    };

    const mockTranslationService = {
      t: (key: string) => key
    };

    const mockToastService = {
      success: vi.fn(),
      error: vi.fn()
    };

    await TestBed.configureTestingModule({
      imports: [ContactsPage, HttpClientTestingModule, RouterTestingModule],
      providers: [
        { provide: ContactService, useValue: mockContactService },
        { provide: TranslationService, useValue: mockTranslationService },
        { provide: ToastService, useValue: mockToastService }
      ]
    }).compileComponents();

    fixture = TestBed.createComponent(ContactsPage);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create the contacts component', () => {
    expect(component).toBeTruthy();
  });
});
