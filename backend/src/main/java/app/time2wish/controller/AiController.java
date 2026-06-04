package app.time2wish.controller;

import app.time2wish.dto.AiRequest;
import app.time2wish.dto.AiResponse;
import app.time2wish.dto.MessageResponse;
import app.time2wish.model.Birthday;
import app.time2wish.model.User;
import app.time2wish.repository.UserRepository;
import app.time2wish.service.BirthdayService;
import app.time2wish.service.GeminiService;
import app.time2wish.security.UserDetailsImpl;
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
    private GeminiService geminiService;

    @Autowired
    private BirthdayService birthdayService;

    @Autowired
    private UserRepository userRepository;

    private User getAuthenticatedUser(UserDetailsImpl userDetails) {
        return userRepository.findById(userDetails.getId())
                .orElseThrow(() -> new RuntimeException("Error: Authenticated user not found in DB"));
    }

    @PostMapping("/generate")
    public ResponseEntity<?> generateWish(
            @Valid @RequestBody AiRequest request,
            @AuthenticationPrincipal UserDetailsImpl userDetails) {
        
        User user = getAuthenticatedUser(userDetails);
        
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

        String wish = geminiService.generateWish(
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
}
