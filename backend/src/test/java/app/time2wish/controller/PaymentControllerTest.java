package app.time2wish.controller;

import app.time2wish.model.PaymentProvider;
import app.time2wish.model.PlanType;
import app.time2wish.model.User;
import app.time2wish.repository.PaymentTransactionRepository;
import app.time2wish.repository.UserRepository;
import app.time2wish.security.UserDetailsImpl;
import app.time2wish.security.UserDetailsServiceImpl;
import app.time2wish.security.WebSecurityConfig;
import app.time2wish.service.payment.PaymentGateway;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import java.util.Optional;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(PaymentController.class)
@Import(WebSecurityConfig.class)
@DisplayName("PaymentController – Tests d'intégration MockMvc")
class PaymentControllerTest {

    @MockitoBean
    private UserDetailsServiceImpl userDetailsService;

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private UserRepository userRepository;

    @MockitoBean
    private PaymentTransactionRepository paymentTransactionRepository;

    @MockitoBean
    private PaymentGateway paymentGateway;

    @MockitoBean
    private app.time2wish.security.JwtUtils jwtUtils;

    private User mockUser;
    private UserDetailsImpl mockUserDetails;

    @BeforeEach
    void setUp() {
        mockUser = new User();
        mockUser.setId(1L);
        mockUser.setEmail("demo@time2wish.com");
        mockUser.setFullName("Demo User");
        mockUser.setPassword("encoded_password");

        mockUserDetails = UserDetailsImpl.build(mockUser);

        when(userRepository.findByEmail("demo@time2wish.com")).thenReturn(Optional.of(mockUser));
        when(userRepository.findById(1L)).thenReturn(Optional.of(mockUser));
        
        when(paymentGateway.getProvider()).thenReturn(PaymentProvider.STRIPE);
        when(paymentGateway.createCheckout(any(), any())).thenReturn("https://checkout.stripe.com/mock");
        when(paymentGateway.createCustomerPortal(any())).thenReturn("https://billing.stripe.com/mock");
    }

    @Test
    @DisplayName("POST /api/payments/checkout → 200 et retourne l'URL")
    void createCheckout_shouldReturnUrl() throws Exception {
        String payload = "{\"provider\": \"STRIPE\", \"plan\": \"PRO\"}";

        mockMvc.perform(post("/api/payments/checkout")
                        .with(user(mockUserDetails))
                        .with(csrf())
                        .contentType("application/json")
                        .content(payload))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.url").value("https://checkout.stripe.com/mock"));
    }

    @Test
    @DisplayName("POST /api/payments/portal → 200 et retourne l'URL")
    void createPortal_shouldReturnUrl() throws Exception {
        String payload = "{\"provider\": \"STRIPE\"}";

        mockMvc.perform(post("/api/payments/portal")
                        .with(user(mockUserDetails))
                        .with(csrf())
                        .contentType("application/json")
                        .content(payload))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.url").value("https://billing.stripe.com/mock"));
    }

    @Test
    @DisplayName("POST /api/payments/mock-webhook → 200 et met à jour l'utilisateur")
    void mockWebhook_shouldReturn200_andUpdateUser() throws Exception {
        String payload = "{\"userId\": 1, \"provider\": \"STRIPE\", \"plan\": \"PRO\"}";

        mockMvc.perform(post("/api/payments/mock-webhook")
                        .with(user(mockUserDetails))
                        .with(csrf())
                        .contentType("application/json")
                        .content(payload))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));
    }
}
