package app.time2wish.controller;

import app.time2wish.dto.TimeCapsuleResponseDto;
import app.time2wish.security.UserDetailsImpl;
import app.time2wish.service.TimeCapsuleService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/api")
@CrossOrigin(origins = "*", maxAge = 3600)
public class TimeCapsuleController {

    private final TimeCapsuleService timeCapsuleService;

    public TimeCapsuleController(TimeCapsuleService timeCapsuleService) {
        this.timeCapsuleService = timeCapsuleService;
    }

    // Public endpoint for guests to upload videos
    @PostMapping("/public/shared/{token}/time-capsule/upload")
    public ResponseEntity<?> uploadVideo(
            @PathVariable String token,
            @RequestParam("guestName") String guestName,
            @RequestParam("file") MultipartFile file) {
        try {
            timeCapsuleService.uploadVideo(token, guestName, file);
            return ResponseEntity.ok().build();
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(e.getMessage());
        }
    }

    // Private endpoint for the host to get videos
    @GetMapping("/birthdays/{id}/time-capsule")
    public ResponseEntity<TimeCapsuleResponseDto> getCapsuleStatus(
            @PathVariable Long id,
            @AuthenticationPrincipal UserDetailsImpl userDetails) {
        try {
            TimeCapsuleResponseDto response = timeCapsuleService.getCapsuleStatus(id, userDetails.getId());
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
        }
    }

    // Private endpoint to mark video as viewed (and delete file)
    @PostMapping("/birthdays/{id}/time-capsule/{videoId}/mark-viewed")
    public ResponseEntity<?> markAsViewed(
            @PathVariable Long id,
            @PathVariable Long videoId,
            @AuthenticationPrincipal UserDetailsImpl userDetails) {
        try {
            timeCapsuleService.markAsViewed(id, videoId, userDetails.getId());
            return ResponseEntity.ok().build();
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(e.getMessage());
        }
    }
}
