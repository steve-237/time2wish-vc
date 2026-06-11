package app.time2wish.controller;

import app.time2wish.dto.AdminPasswordUpdateRequest;
import app.time2wish.dto.AdminUserDto;
import app.time2wish.dto.StatsResponse;
import app.time2wish.service.AdminService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import jakarta.validation.Valid;

import java.util.List;

@RestController
@RequestMapping("/api/admin")
@PreAuthorize("hasRole('ADMIN') or hasRole('SUPERADMIN')")
public class AdminController {

    private final AdminService adminService;

    public AdminController(AdminService adminService) {
        this.adminService = adminService;
    }

    @GetMapping("/test")
    public ResponseEntity<String> adminTest() {
        return ResponseEntity.ok("Admin access granted.");
    }



    @GetMapping("/stats")
    public ResponseEntity<StatsResponse> getStats() {
        org.springframework.security.core.Authentication auth = org.springframework.security.core.context.SecurityContextHolder.getContext().getAuthentication();
        boolean isSuperAdmin = auth.getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("ROLE_SUPERADMIN"));

        if (isSuperAdmin) {
            return ResponseEntity.ok(adminService.getStats());
        } else {
            return ResponseEntity.ok(adminService.getStatsForRole(app.time2wish.model.Role.ROLE_USER));
        }
    }
}
