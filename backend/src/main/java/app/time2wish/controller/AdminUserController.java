package app.time2wish.controller;

import app.time2wish.model.PlanType;
import app.time2wish.model.Role;
import app.time2wish.model.User;
import app.time2wish.repository.UserRepository;
import app.time2wish.security.UserDetailsImpl;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.Optional;

@CrossOrigin(origins = "*", maxAge = 3600)
@RestController
@RequestMapping("/api/admin/users")
public class AdminUserController {

    @Autowired
    private UserRepository userRepository;

    @GetMapping
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPERADMIN')")
    public ResponseEntity<?> getAllUsers() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        boolean isSuperAdmin = auth.getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("ROLE_SUPERADMIN"));

        List<User> users;
        if (isSuperAdmin) {
            users = userRepository.findAll();
        } else {
            users = userRepository.findByRole(Role.ROLE_USER);
        }
        
        // Hide passwords
        users.forEach(u -> u.setPassword(null));
        return ResponseEntity.ok(users);
    }

    @PutMapping("/{id}/status")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPERADMIN')")
    public ResponseEntity<?> updateStatus(@PathVariable Long id, @RequestBody Map<String, String> request) {
        String newStatus = request.get("status");
        if (newStatus == null) return ResponseEntity.badRequest().body("Status is required");

        Optional<User> userOpt = userRepository.findById(id);
        if (userOpt.isEmpty()) return ResponseEntity.notFound().build();
        User user = userOpt.get();

        // Prevent admin from blocking superadmin
        if (user.getRole() == Role.ROLE_SUPERADMIN) {
            return ResponseEntity.status(403).body("Cannot modify SuperAdmin");
        }

        user.setStatus(newStatus);
        userRepository.save(user);
        return ResponseEntity.ok(Map.of("message", "Status updated successfully", "status", newStatus));
    }

    @PutMapping("/{id}/plan")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPERADMIN')")
    public ResponseEntity<?> updatePlan(@PathVariable Long id, @RequestBody Map<String, String> request) {
        String planStr = request.get("plan");
        if (planStr == null) return ResponseEntity.badRequest().body("Plan is required");

        Optional<User> userOpt = userRepository.findById(id);
        if (userOpt.isEmpty()) return ResponseEntity.notFound().build();
        User user = userOpt.get();

        if (user.getRole() == Role.ROLE_SUPERADMIN) {
            return ResponseEntity.status(403).body("Cannot modify SuperAdmin");
        }

        try {
            PlanType newPlan = PlanType.valueOf(planStr.toUpperCase());
            user.setPlan(newPlan);
            userRepository.save(user);
            return ResponseEntity.ok(Map.of("message", "Plan updated successfully", "plan", newPlan.name()));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body("Invalid plan type");
        }
    }

    @PutMapping("/{id}/role")
    @PreAuthorize("hasRole('SUPERADMIN')")
    public ResponseEntity<?> updateRole(@PathVariable Long id, @RequestBody Map<String, String> request) {
        String roleStr = request.get("role");
        if (roleStr == null) return ResponseEntity.badRequest().body("Role is required");

        Optional<User> userOpt = userRepository.findById(id);
        if (userOpt.isEmpty()) return ResponseEntity.notFound().build();
        User user = userOpt.get();

        if (user.getId() == 1L) {
            return ResponseEntity.status(403).body("Cannot modify root SuperAdmin");
        }

        try {
            Role newRole = Role.valueOf(roleStr);
            user.setRole(newRole);
            userRepository.save(user);
            return ResponseEntity.ok(Map.of("message", "Role updated successfully", "role", newRole.name()));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body("Invalid role type");
        }
    }
}
