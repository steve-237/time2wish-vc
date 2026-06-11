package app.time2wish.controller;

import app.time2wish.model.PlanType;
import app.time2wish.model.User;
import app.time2wish.repository.UserRepository;
import app.time2wish.security.UserDetailsImpl;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/users")
public class UserController {

    @Autowired
    private UserRepository userRepository;

    @PutMapping("/me/plan")
    public ResponseEntity<?> updateMyPlan(@AuthenticationPrincipal UserDetailsImpl userDetails, @RequestBody Map<String, String> request) {
        String planStr = request.get("plan");
        if (planStr == null) {
            return ResponseEntity.badRequest().body("Plan is required");
        }

        User user = userRepository.findById(userDetails.getId())
                .orElseThrow(() -> new RuntimeException("Error: User not found"));

        try {
            PlanType newPlan = PlanType.valueOf(planStr.toUpperCase());
            user.setPlan(newPlan);
            userRepository.save(user);
            return ResponseEntity.ok(Map.of(
                    "message", "Plan updated successfully",
                    "plan", newPlan.name()
            ));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body("Invalid plan type");
        }
    }
}
