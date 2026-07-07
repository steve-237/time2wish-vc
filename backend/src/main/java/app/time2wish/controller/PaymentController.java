package app.time2wish.controller;

import app.time2wish.model.PaymentProvider;
import app.time2wish.model.PlanType;
import app.time2wish.model.User;
import app.time2wish.model.PaymentTransaction;
import app.time2wish.repository.UserRepository;
import app.time2wish.repository.PaymentTransactionRepository;
import app.time2wish.service.payment.PaymentGateway;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/api/payments")
public class PaymentController {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PaymentTransactionRepository paymentTransactionRepository;

    @Autowired
    private List<PaymentGateway> gateways;

    static class CheckoutRequest {
        public PaymentProvider provider;
        public PlanType plan;
    }

    @PostMapping("/checkout")
    public ResponseEntity<?> createCheckout(@RequestBody CheckoutRequest request, Authentication authentication) {
        String email = authentication.getName();
        User user = userRepository.findByEmail(email).orElseThrow();

        PaymentGateway gateway = gateways.stream()
                .filter(g -> g.getProvider() == request.provider)
                .findFirst()
                .orElseThrow(() -> new IllegalArgumentException("Unsupported provider"));

        String url = gateway.createCheckout(user, request.plan);
        return ResponseEntity.ok(Map.of("url", url));
    }

    @PostMapping("/portal")
    public ResponseEntity<?> createPortal(@RequestBody Map<String, String> payload, Authentication authentication) {
        String email = authentication.getName();
        User user = userRepository.findByEmail(email).orElseThrow();
        
        PaymentProvider provider = PaymentProvider.valueOf(payload.getOrDefault("provider", "STRIPE"));

        PaymentGateway gateway = gateways.stream()
                .filter(g -> g.getProvider() == provider)
                .findFirst()
                .orElseThrow();

        String url = gateway.createCustomerPortal(user);
        return ResponseEntity.ok(Map.of("url", url));
    }

    // MOCK Webhook to simulate a successful payment
    @PostMapping("/mock-webhook")
    public ResponseEntity<?> mockWebhook(@RequestBody Map<String, Object> payload) {
        Long userId = Long.valueOf(payload.get("userId").toString());
        PaymentProvider provider = PaymentProvider.valueOf(payload.get("provider").toString());
        PlanType plan = PlanType.valueOf(payload.get("plan").toString());

        Optional<User> optUser = userRepository.findById(userId);
        if (optUser.isEmpty()) return ResponseEntity.notFound().build();
        User user = optUser.get();

        // 1. Update User Plan
        user.setPlan(plan);
        user.setSubscriptionProvider(provider.name());
        user.setSubscriptionStatus("ACTIVE");
        user.setSubscriptionExpiresAt(LocalDateTime.now().plusMonths(1));
        userRepository.save(user);

        // 2. Record Transaction
        Double amount = plan == PlanType.PRO ? 9.99 : (plan == PlanType.PLUS ? 4.99 : 0.0);
        PaymentTransaction tx = PaymentTransaction.builder()
                .user(user)
                .provider(provider.name())
                .amount(amount)
                .currency("EUR")
                .plan(plan.name())
                .status("SUCCESS")
                .providerTransactionId("mock_tx_" + System.currentTimeMillis())
                .build();
        paymentTransactionRepository.save(tx);

        return ResponseEntity.ok(Map.of("success", true));
    }
}
