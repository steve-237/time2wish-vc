package app.time2wish.service.payment;

import app.time2wish.model.PaymentProvider;
import app.time2wish.model.PlanType;
import app.time2wish.model.User;
import org.springframework.stereotype.Service;

@Service
public class StripeMockGateway implements PaymentGateway {
    @Override
    public PaymentProvider getProvider() { return PaymentProvider.STRIPE; }
    @Override
    public String createCheckout(User user, PlanType planType) {
        return "/payment/mock-checkout?provider=STRIPE&plan=" + planType.name();
    }
    @Override
    public String createCustomerPortal(User user) {
        return "/payment/mock-portal?provider=STRIPE";
    }
}
