package app.time2wish.controller;

import app.time2wish.model.User;
import app.time2wish.repository.UserRepository;
import app.time2wish.security.UserDetailsImpl;
import app.time2wish.service.GoogleIntegrationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/google")
public class GoogleIntegrationController {

    @Autowired
    private GoogleIntegrationService googleIntegrationService;

    @Autowired
    private UserRepository userRepository;

    private User getAuthenticatedUser(UserDetailsImpl userDetails) {
        return userRepository.findById(userDetails.getId())
                .orElseThrow(() -> new RuntimeException("Error: Authenticated user not found in DB"));
    }

    @GetMapping("/auth-url")
    public ResponseEntity<?> getAuthUrl() {
        return ResponseEntity.ok(Map.of("url", googleIntegrationService.getAuthorizationUrl()));
    }

    @PostMapping("/callback")
    public ResponseEntity<?> handleCallback(@RequestBody Map<String, String> payload, @AuthenticationPrincipal UserDetailsImpl userDetails) {
        try {
            User user = getAuthenticatedUser(userDetails);
            String code = payload.get("code");
            googleIntegrationService.exchangeCodeForToken(code, user);
            return ResponseEntity.ok(Map.of("message", "Google account successfully linked"));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    @PostMapping("/sync-contacts")
    public ResponseEntity<?> syncContacts(@AuthenticationPrincipal UserDetailsImpl userDetails) {
        try {
            User user = getAuthenticatedUser(userDetails);
            int imported = googleIntegrationService.importContacts(user);
            return ResponseEntity.ok(Map.of("message", imported + " contacts importés avec succès."));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    @PostMapping("/sync-calendar")
    public ResponseEntity<?> syncCalendar(@AuthenticationPrincipal UserDetailsImpl userDetails) {
        try {
            User user = getAuthenticatedUser(userDetails);
            int exported = googleIntegrationService.exportBirthdaysToCalendar(user);
            return ResponseEntity.ok(Map.of("message", exported + " anniversaires exportés vers Google Calendar avec succès."));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }
}
