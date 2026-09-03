package app.time2wish.controller;

import app.time2wish.dto.JwtResponse;
import app.time2wish.model.PlanType;
import app.time2wish.model.User;
import app.time2wish.repository.UserBadgeRepository;
import app.time2wish.repository.UserRepository;
import app.time2wish.security.UserDetailsImpl;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.Collections;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/users")
public class UserController {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private UserBadgeRepository userBadgeRepository;

    @GetMapping("/me")
    public ResponseEntity<?> getMyProfile(@AuthenticationPrincipal UserDetailsImpl userDetails) {
        if (userDetails == null) {
            return ResponseEntity.status(401).body(Map.of("message", "Unauthorized"));
        }

        User user = userRepository.findById(userDetails.getId())
                .orElseThrow(() -> new RuntimeException("Error: User not found"));

        JwtResponse response = JwtResponse.builder()
                .id(user.getId())
                .email(user.getEmail())
                .fullName(user.getFullName())
                .bio(user.getBio())
                .avatarUrl(user.getAvatarUrl())
                .roles(Collections.singletonList(user.getRole().name()))
                .plan(user.getPlan() != null ? user.getPlan().name() : "BASIC")
                .lastAiWishGeneration(user.getLastAiWishGeneration())
                .lastAiGiftGeneration(user.getLastAiGiftGeneration())
                .badges(userBadgeRepository.findByUser(user).stream().map(app.time2wish.model.UserBadge::getBadgeName).collect(Collectors.toList()))
                .coins(user.getCoins())
                .build();

        return ResponseEntity.ok(response);
    }

    @PutMapping("/me/plan")
    public ResponseEntity<?> updateMyPlan(@AuthenticationPrincipal UserDetailsImpl userDetails, @RequestBody Map<String, String> request) {
        if (userDetails == null) {
            return ResponseEntity.status(401).body(Map.of("message", "Unauthorized"));
        }

        String planStr = request.get("plan");
        if (planStr == null) {
            return ResponseEntity.badRequest().body(Map.of("message", "Plan is required"));
        }

        User user = userRepository.findById(userDetails.getId())
                .orElseThrow(() -> new RuntimeException("Error: User not found"));

        try {
            PlanType newPlan = PlanType.valueOf(planStr.toUpperCase());
            user.setPlan(newPlan);
            user.setSubscriptionStatus("ACTIVE");
            userRepository.save(user);

            JwtResponse response = JwtResponse.builder()
                    .id(user.getId())
                    .email(user.getEmail())
                    .fullName(user.getFullName())
                    .bio(user.getBio())
                    .avatarUrl(user.getAvatarUrl())
                    .roles(Collections.singletonList(user.getRole().name()))
                    .plan(newPlan.name())
                    .lastAiWishGeneration(user.getLastAiWishGeneration())
                    .lastAiGiftGeneration(user.getLastAiGiftGeneration())
                    .badges(userBadgeRepository.findByUser(user).stream().map(app.time2wish.model.UserBadge::getBadgeName).collect(Collectors.toList()))
                    .coins(user.getCoins())
                    .build();

            return ResponseEntity.ok(response);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("message", "Invalid plan type"));
        }
    }
}
