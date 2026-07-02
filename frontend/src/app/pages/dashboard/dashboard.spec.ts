import { ComponentFixture, TestBed } from '@angular/core/testing';
import { Dashboard } from './dashboard';
import { HttpClientTestingModule } from '@angular/common/http/testing';
import { RouterTestingModule } from '@angular/router/testing';
import { BirthdayService } from '../../services/birthday.service';
import { TranslationService } from '../../services/translation.service';
import { ToastService } from '../../services/toast.service';
import { AudioService } from '../../services/audio.service';
import { NotificationService } from '../../services/notification.service';
import { ExportService } from '../../services/export.service';
import { ConfettiService } from '../../services/confetti.service';
import { AuthService } from '../../services/auth.service';
import { UiService } from '../../services/ui.service';
import { of } from 'rxjs';

describe('Dashboard Component', () => {
  let component: Dashboard;
  let fixture: ComponentFixture<Dashboard>;

  beforeEach(async () => {
    // Mock services
    const mockBirthdayService = {
      isLoading: () => false,
      birthdays: () => [],
      statistics: () => ({ total: 0, todayCount: 0, thisMonthCount: 0, next30DaysCount: 0 }),
      loadBirthdays: () => of([]),
      triggerReminders: () => of({ success: true, count: 0 })
    };

    const mockAuthService = {
      currentUser: () => ({ id: 1, plan: 'PRO' })
    };

    const mockTranslationService = {
      t: (key: string) => key,
      currentLang: () => 'fr'
    };

    const mockUiService = {
      isPricingModalOpen: { set: vi.fn() }
    };

    const mockToastService = { info: vi.fn(), success: vi.fn() };
    const mockAudioService = { play: vi.fn() };
    const mockNotificationService = { requestPermission: vi.fn() };
    const mockExportService = {};
    const mockConfettiService = { init: vi.fn() };

    await TestBed.configureTestingModule({
      imports: [Dashboard, HttpClientTestingModule, RouterTestingModule],
      providers: [
        { provide: BirthdayService, useValue: mockBirthdayService },
        { provide: TranslationService, useValue: mockTranslationService },
        { provide: ToastService, useValue: mockToastService },
        { provide: AudioService, useValue: mockAudioService },
        { provide: NotificationService, useValue: mockNotificationService },
        { provide: ExportService, useValue: mockExportService },
        { provide: ConfettiService, useValue: mockConfettiService },
        { provide: AuthService, useValue: mockAuthService },
        { provide: UiService, useValue: mockUiService }
      ]
    }).compileComponents();

    fixture = TestBed.createComponent(Dashboard);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create the dashboard component', () => {
    expect(component).toBeTruthy();
  });

  it('should require plan appropriately', () => {
    const actionSpy = vi.fn();
    component.requirePlan('PLUS', actionSpy);
    expect(actionSpy).toHaveBeenCalled();
  });
});
