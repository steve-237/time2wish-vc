package app.time2wish.controller;

import app.time2wish.model.Announcement;
import app.time2wish.repository.AnnouncementRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api")
public class AnnouncementController {

    private final AnnouncementRepository announcementRepository;

    @Autowired
    public AnnouncementController(AnnouncementRepository announcementRepository) {
        this.announcementRepository = announcementRepository;
    }

    // --- PUBLIC ENDPOINT ---
    @GetMapping("/announcements/active")
    public ResponseEntity<?> getActiveAnnouncement() {
        return announcementRepository.findFirstByIsActiveTrueOrderByCreatedAtDesc()
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.noContent().build());
    }

    // --- ADMIN ENDPOINTS ---
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPERADMIN')")
    @GetMapping("/admin/announcements")
    public ResponseEntity<List<Announcement>> getAllAnnouncements() {
        return ResponseEntity.ok(announcementRepository.findAll());
    }

    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPERADMIN')")
    @PostMapping("/admin/announcements")
    public ResponseEntity<Announcement> createAnnouncement(@RequestBody Announcement request) {
        // If the new one is active, we might want to deactivate others. For simplicity, just save.
        Announcement announcement = Announcement.builder()
                .title(request.getTitle())
                .message(request.getMessage())
                .type(request.getType() != null ? request.getType() : "INFO")
                .isActive(request.isActive())
                .build();
        return ResponseEntity.ok(announcementRepository.save(announcement));
    }

    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPERADMIN')")
    @PutMapping("/admin/announcements/{id}/toggle")
    public ResponseEntity<Announcement> toggleAnnouncement(@PathVariable Long id) {
        Announcement ann = announcementRepository.findById(id).orElseThrow();
        ann.setActive(!ann.isActive());
        return ResponseEntity.ok(announcementRepository.save(ann));
    }
}
