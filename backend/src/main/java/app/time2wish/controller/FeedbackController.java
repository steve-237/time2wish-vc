package app.time2wish.controller;

import app.time2wish.model.Feedback;
import app.time2wish.model.User;
import app.time2wish.repository.FeedbackRepository;
import app.time2wish.repository.UserRepository;
import app.time2wish.security.UserDetailsImpl;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import jakarta.validation.Valid;

import java.util.List;

@RestController
@RequestMapping("/api")
public class FeedbackController {

    @Autowired
    private FeedbackRepository feedbackRepository;

    @Autowired
    private UserRepository userRepository;

    // --- USER ENDPOINT ---
    @PostMapping("/feedbacks")
    public ResponseEntity<?> submitFeedback(
            @RequestBody Feedback request,
            @AuthenticationPrincipal UserDetailsImpl userDetails) {
        
        User user = userRepository.findById(userDetails.getId())
                .orElseThrow(() -> new RuntimeException("Error: User not found."));

        Feedback feedback = Feedback.builder()
                .user(user)
                .rating(request.getRating())
                .comment(request.getComment())
                .build();
        
        return ResponseEntity.ok(feedbackRepository.save(feedback));
    }

    // --- ADMIN ENDPOINTS ---
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPERADMIN')")
    @GetMapping("/admin/feedbacks")
    public ResponseEntity<List<Feedback>> getAllFeedbacks() {
        return ResponseEntity.ok(feedbackRepository.findAll(org.springframework.data.domain.Sort.by(org.springframework.data.domain.Sort.Direction.DESC, "createdAt")));
    }
}
