import { ComponentFixture, TestBed } from '@angular/core/testing';
import { PricingComponent } from './pricing.component';
import { HttpClientTestingModule } from '@angular/common/http/testing';
import { RouterTestingModule } from '@angular/router/testing';
import { AuthService } from '../../services/auth.service';
import { TranslationService } from '../../services/translation.service';
import { ToastService } from '../../services/toast.service';
import { HttpClient } from '@angular/common/http';
import { of, throwError } from 'rxjs';

describe('PricingComponent', () => {
  let component: PricingComponent;
  let fixture: ComponentFixture<PricingComponent>;
  let mockAuthService: any;
  let mockToastService: any;
  let mockHttp: any;

  beforeEach(async () => {
    mockAuthService = {
      currentUser: vi.fn().mockReturnValue({ plan: 'BASIC' })
    };

    const mockTranslationService = {
      t: vi.fn((key: string) => key),
      currentLang: vi.fn().mockReturnValue('fr')
    };

    mockToastService = {
      success: vi.fn(),
      error: vi.fn()
    };

    mockHttp = {
      post: vi.fn().mockReturnValue(of({ url: 'https://checkout.stripe.com/mock' }))
    };

    await TestBed.configureTestingModule({
      imports: [PricingComponent, HttpClientTestingModule, RouterTestingModule],
      providers: [
        { provide: AuthService, useValue: mockAuthService },
        { provide: TranslationService, useValue: mockTranslationService },
        { provide: ToastService, useValue: mockToastService },
        { provide: HttpClient, useValue: mockHttp }
      ]
    }).compileComponents();

    fixture = TestBed.createComponent(PricingComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create the pricing component', () => {
    expect(component).toBeTruthy();
  });

  it('should reflect current plan', () => {
    expect(component.currentPlan()).toBe('BASIC');
  });

  it('should open confirmation modal when plan is selected', () => {
    component.selectPlan('PRO');
    expect(component.planToConfirm()).toBe('PRO');
  });

  it('should cancel plan change', () => {
    component.selectPlan('PRO');
    component.cancelPlanChange();
    expect(component.planToConfirm()).toBeNull();
  });

  it('should process checkout successfully', () => {
    // Mock window.location.href (using Object.defineProperty if needed, but since it's vitest/jsdom, we can just spy on the post)
    component.selectPlan('PRO');
    component.checkoutWith('STRIPE');

    expect(component.isLoading()).toBe(true);
    expect(mockHttp.post).toHaveBeenCalled();
    // It's tricky to mock window.location.href directly in vitest without setup, so we just verify the http call
  });

  it('should handle checkout error', () => {
    component.selectPlan('PRO');
    mockHttp.post.mockReturnValue(throwError(() => new Error('Error')));
    
    component.checkoutWith('STRIPE');

    expect(component.isLoading()).toBe(false);
    expect(mockToastService.error).toHaveBeenCalledWith('Erreur lors de l\'initialisation du paiement');
  });
});
