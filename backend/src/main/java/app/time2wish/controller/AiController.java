package app.time2wish.controller;

import app.time2wish.dto.AiRequest;
import app.time2wish.dto.AiResponse;
import app.time2wish.dto.MessageResponse;
import app.time2wish.model.Birthday;
import app.time2wish.model.User;
import app.time2wish.repository.UserRepository;
import app.time2wish.service.BirthdayService;
import app.time2wish.service.IAService;
import app.time2wish.service.ImageGenerationService;
import app.time2wish.security.UserDetailsImpl;
import app.time2wish.dto.AiCardRequest;
import org.springframework.http.MediaType;
import org.springframework.http.HttpHeaders;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import java.time.Period;

@CrossOrigin(origins = "http://localhost:4200", maxAge = 3600, allowCredentials="true")
@RestController
@RequestMapping("/api/ai")
public class AiController {

    @Autowired
    private IAService IAService;

    @Autowired
    private ImageGenerationService imageGenerationService;

    @Autowired
    private BirthdayService birthdayService;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private app.time2wish.repository.AILogRepository aiLogRepository;

    private User getAuthenticatedUser(UserDetailsImpl userDetails) {
        return userRepository.findById(userDetails.getId())
                .orElseThrow(() -> new RuntimeException("Error: Authenticated user not found in DB"));
    }

    @PostMapping("/generate")
    public ResponseEntity<?> generateWish(
            @Valid @RequestBody AiRequest request,
            @AuthenticationPrincipal UserDetailsImpl userDetails) {
        
        User user = getAuthenticatedUser(userDetails);
        
        if (user.getPlan() == app.time2wish.model.PlanType.BASIC) {
            java.time.LocalDateTime lastGen = user.getLastAiWishGeneration();
            if (lastGen != null && lastGen.plusDays(7).isAfter(java.time.LocalDateTime.now())) {
                java.time.Duration duration = java.time.Duration.between(java.time.LocalDateTime.now(), lastGen.plusDays(7));
                long days = duration.toDays();
                long hours = duration.toHoursPart();
                return ResponseEntity.status(429).body(new MessageResponse(String.format("Prochaine génération disponible dans %dj %dh", days, hours)));
            }
            user.setLastAiWishGeneration(java.time.LocalDateTime.now());
            userRepository.save(user);
        }
        
        // Retrieve birthday and check owner
        Birthday birthday = birthdayService.getBirthday(request.getBirthdayId(), user)
                .orElse(null);
        
        if (birthday == null) {
            return ResponseEntity.status(404).body(new MessageResponse("Error: Birthday not found"));
        }

        // Calculate age
        Integer age = null;
        if (birthday.getBirthdate() != null) {
            try {
                age = Period.between(java.time.LocalDate.parse(birthday.getBirthdate().toString()), java.time.LocalDate.now()).getYears();
            } catch (Exception e) {
                // Ignore age calculation errors if date string parsing fails
            }
        }

        String lang = request.getLang() != null ? request.getLang() : "fr";

        String wish = IAService.generateWish(
                birthday.getName(),
                age,
                birthday.getCategory(),
                birthday.getNotes(),
                request.getTone(),
                lang,
                request.getExtraInstructions()
        );

        return ResponseEntity.ok(new AiResponse(wish));
    }

    @PostMapping("/card")
    public ResponseEntity<?> generateCard(
            @Valid @RequestBody AiCardRequest request,
            @AuthenticationPrincipal UserDetailsImpl userDetails) {
        
        // Ensure user is authenticated
        User user = getAuthenticatedUser(userDetails);
        
        if (user.getPlan() != app.time2wish.model.PlanType.PRO) {
            return ResponseEntity.status(403).body(new MessageResponse("La génération d'images nécessite le forfait PREMIUM."));
        }
        
        byte[] imageBytes = imageGenerationService.generateImage(request.getPrompt());
        
        if (imageBytes == null) {
            return ResponseEntity.status(503).body(new MessageResponse("L'API de génération d'images n'est pas configurée pour le moment."));
        }

        // Log AI usage for image generation
        app.time2wish.model.AILog log = app.time2wish.model.AILog.builder()
                .user(user)
                .featureType("IMAGE")
                .tokensCost(5) // maybe images cost more tokens
                .build();
        aiLogRepository.save(log);

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.IMAGE_JPEG);
        return new ResponseEntity<>(imageBytes, headers, 200);
    }
}
