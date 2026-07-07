package app.time2wish.service.payment;

import app.time2wish.model.PaymentProvider;
import app.time2wish.model.PlanType;
import app.time2wish.model.User;
import org.springframework.stereotype.Service;

@Service
public class MoMoMockGateway implements PaymentGateway {
    @Override
    public PaymentProvider getProvider() { return PaymentProvider.MOMO; }
    @Override
    public String createCheckout(User user, PlanType planType) {
        return "http://localhost:4200/payment/mock-checkout?provider=MOMO&plan=" + planType.name();
    }
    @Override
    public String createCustomerPortal(User user) {
        return "http://localhost:4200/payment/mock-portal?provider=MOMO";
    }
}