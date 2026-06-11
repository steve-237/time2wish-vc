package app.time2wish.controller;

import app.time2wish.model.PlanType;
import app.time2wish.model.Role;
import app.time2wish.model.User;
import app.time2wish.repository.UserRepository;
import app.time2wish.security.JwtUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@CrossOrigin(origins = "*", maxAge = 3600)
@RestController
@RequestMapping("/api/admin/auth")
public class AdminAuthController {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PasswordEncoder encoder;

    @Autowired
    private JwtUtils jwtUtils;

    @PostMapping("/signup")
    public ResponseEntity<?> registerAdmin(@RequestBody Map<String, String> signUpRequest) {
        if (userRepository.existsByEmail(signUpRequest.get("email"))) {
            return ResponseEntity
                    .badRequest()
                    .body(Map.of("message", "Error: Email is already in use!"));
        }

        // Create new admin account with PENDING_APPROVAL status
        User user = User.builder()
                .email(signUpRequest.get("email"))
                .password(encoder.encode(signUpRequest.get("password")))
                .fullName(signUpRequest.get("fullName"))
                .role(Role.ROLE_ADMIN)
                .status("PENDING_APPROVAL")
                .plan(PlanType.BASIC)
                .build();

        userRepository.save(user);

        return ResponseEntity.ok(Map.of("message", "Admin registered successfully! Waiting for SuperAdmin approval."));
    }
}
