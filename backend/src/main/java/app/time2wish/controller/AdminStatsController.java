package app.time2wish.controller;

import app.time2wish.repository.AILogRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDateTime;

@RestController
@RequestMapping("/api/admin/stats")
@PreAuthorize("hasRole('ADMIN') or hasRole('SUPERADMIN')")
public class AdminStatsController {

    private final AILogRepository aiLogRepository;

    @Autowired
    public AdminStatsController(AILogRepository aiLogRepository) {
        this.aiLogRepository = aiLogRepository;
    }

    @GetMapping("/ai")
    public ResponseEntity<?> getAiStats() {
        // Stats from the last 30 days
        LocalDateTime since = LocalDateTime.now().minusDays(30);
        return ResponseEntity.ok(aiLogRepository.countStatsByFeatureSince(since));
    }
}
