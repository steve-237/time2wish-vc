package app.time2wish.controller;

import app.time2wish.dto.MessageResponse;
import app.time2wish.dto.TemplateRequest;
import app.time2wish.dto.TemplateResponse;
import app.time2wish.model.MessageTemplate;
import app.time2wish.model.User;
import app.time2wish.repository.TemplateRepository;
import app.time2wish.repository.UserRepository;
import app.time2wish.security.UserDetailsImpl;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.stream.Collectors;

@CrossOrigin(origins = "http://localhost:4200", maxAge = 3600, allowCredentials="true")
@RestController
@RequestMapping("/api/templates")
public class TemplateController {

    @Autowired
    private TemplateRepository templateRepository;

    @Autowired
    private UserRepository userRepository;

    private User getAuthenticatedUser(UserDetailsImpl userDetails) {
        return userRepository.findById(userDetails.getId())
                .orElseThrow(() -> new RuntimeException("Error: Authenticated user not found in DB"));
    }

    private TemplateResponse mapToResponse(MessageTemplate template) {
        return new TemplateResponse(
                template.getId(),
                template.getTitle(),
                template.getContent(),
                template.getCategory()
        );
    }

    @GetMapping
    public ResponseEntity<List<TemplateResponse>> getAllTemplates(@AuthenticationPrincipal UserDetailsImpl userDetails) {
        User user = getAuthenticatedUser(userDetails);
        List<TemplateResponse> responseList = templateRepository.findByUser(user)
                .stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
        return ResponseEntity.ok(responseList);
    }

    @PostMapping
    public ResponseEntity<TemplateResponse> createTemplate(
            @Valid @RequestBody TemplateRequest request,
            @AuthenticationPrincipal UserDetailsImpl userDetails) {
        User user = getAuthenticatedUser(userDetails);

        MessageTemplate template = new MessageTemplate(
                user,
                request.getTitle(),
                request.getContent(),
                request.getCategory()
        );

        MessageTemplate saved = templateRepository.save(template);
        return ResponseEntity.status(201).body(mapToResponse(saved));
    }

    @PutMapping("/{id}")
    public ResponseEntity<?> updateTemplate(
            @PathVariable Long id,
            @Valid @RequestBody TemplateRequest request,
            @AuthenticationPrincipal UserDetailsImpl userDetails) {
        User user = getAuthenticatedUser(userDetails);

        MessageTemplate template = templateRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Error: Template not found"));

        if (!template.getUser().getId().equals(user.getId())) {
            return ResponseEntity.status(403).body(new MessageResponse("Error: Unauthorized access to template"));
        }

        template.setTitle(request.getTitle());
        template.setContent(request.getContent());
        template.setCategory(request.getCategory());

        MessageTemplate updated = templateRepository.save(template);
        return ResponseEntity.ok(mapToResponse(updated));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteTemplate(
            @PathVariable Long id,
            @AuthenticationPrincipal UserDetailsImpl userDetails) {
        User user = getAuthenticatedUser(userDetails);

        MessageTemplate template = templateRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Error: Template not found"));

        if (!template.getUser().getId().equals(user.getId())) {
            return ResponseEntity.status(403).body(new MessageResponse("Error: Unauthorized access to template"));
        }

        templateRepository.delete(template);
        return ResponseEntity.ok(new MessageResponse("Template deleted successfully"));
    }
}
