package app.time2wish.service.payment;

import app.time2wish.model.PaymentProvider;
import app.time2wish.model.PlanType;
import app.time2wish.model.User;

public interface PaymentGateway {
    PaymentProvider getProvider();
    
    /**
     * @return the URL to redirect the user to for payment checkout
     */
    String createCheckout(User user, PlanType planType);

    /**
     * @return the URL to the customer portal (for Stripe) or equivalent, if applicable
     */
    String createCustomerPortal(User user);
}
