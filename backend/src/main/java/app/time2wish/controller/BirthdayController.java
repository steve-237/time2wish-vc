package app.time2wish.controller;

import app.time2wish.dto.BirthdayRequest;
import app.time2wish.dto.BirthdayResponse;
import app.time2wish.dto.MessageResponse;
import app.time2wish.model.Birthday;
import app.time2wish.model.User;
import app.time2wish.repository.UserRepository;
import app.time2wish.scheduler.BirthdayReminderScheduler;
import app.time2wish.security.UserDetailsImpl;
import app.time2wish.service.BirthdayService;
import app.time2wish.service.GeminiService;
import app.time2wish.dto.GiftSuggestion;
import jakarta.validation.Valid;
import java.time.LocalDate;
import java.time.Period;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/birthdays")
public class BirthdayController {

    @Autowired
    private BirthdayService birthdayService;

    @Autowired
    private GeminiService geminiService;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private BirthdayReminderScheduler reminderScheduler;

    private User getAuthenticatedUser(UserDetailsImpl userDetails) {
        return userRepository.findById(userDetails.getId())
                .orElseThrow(() -> new RuntimeException("Error: Authenticated user not found in DB"));
    }

    private BirthdayResponse mapToResponse(Birthday b) {
        return BirthdayResponse.builder()
                .id(b.getId())
                .name(b.getName())
                .birthdate(b.getBirthdate())
                .category(b.getCategory())
                .photoUrl(b.getPhotoUrl())
                .notes(b.getNotes())
                .reminderDays(b.getReminderDays())
                .showAge(b.getShowAge())
                .email(b.getEmail())
                .whatsapp(b.getWhatsapp())
                .gender(b.getGender())
                .isDeleted(b.getIsDeleted())
                .createdAt(b.getCreatedAt())
                .interests(b.getInterests())
                .isFavorite(b.getIsFavorite())
                .build();
    }

    @GetMapping
    public ResponseEntity<List<BirthdayResponse>> getAllBirthdays(@AuthenticationPrincipal UserDetailsImpl userDetails) {
        User user = getAuthenticatedUser(userDetails);
        List<BirthdayResponse> responseList = birthdayService.getActiveBirthdays(user)
                .stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
        return ResponseEntity.ok(responseList);
    }

    @GetMapping("/{id}")
    public ResponseEntity<?> getBirthdayById(@PathVariable Long id, @AuthenticationPrincipal UserDetailsImpl userDetails) {
        User user = getAuthenticatedUser(userDetails);
        return birthdayService.getBirthday(id, user)
                .map(this::mapToResponse)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping
    public ResponseEntity<BirthdayResponse> createBirthday(
            @Valid @RequestBody BirthdayRequest request,
            @AuthenticationPrincipal UserDetailsImpl userDetails) {
        User user = getAuthenticatedUser(userDetails);

        Birthday birthday = Birthday.builder()
                .name(request.getName())
                .birthdate(request.getBirthdate())
                .category(request.getCategory())
                .photoUrl(request.getPhotoUrl())
                .notes(request.getNotes())
                .reminderDays(request.getReminderDays())
                .showAge(request.getShowAge())
                .email(request.getEmail())
                .whatsapp(request.getWhatsapp())
                .gender(request.getGender())
                .interests(request.getInterests())
                .isFavorite(request.getIsFavorite() != null ? request.getIsFavorite() : false)
                .build();

        Birthday saved = birthdayService.addBirthday(birthday, user);
        return ResponseEntity.status(201).body(mapToResponse(saved));
    }

    @PutMapping("/{id}")
    public ResponseEntity<?> updateBirthday(
            @PathVariable Long id,
            @Valid @RequestBody BirthdayRequest request,
            @AuthenticationPrincipal UserDetailsImpl userDetails) {
        User user = getAuthenticatedUser(userDetails);

        Birthday birthdayDetails = Birthday.builder()
                .name(request.getName())
                .birthdate(request.getBirthdate())
                .category(request.getCategory())
                .photoUrl(request.getPhotoUrl())
                .notes(request.getNotes())
                .reminderDays(request.getReminderDays())
                .showAge(request.getShowAge())
                .email(request.getEmail())
                .whatsapp(request.getWhatsapp())
                .gender(request.getGender())
                .interests(request.getInterests())
                .isFavorite(request.getIsFavorite() != null ? request.getIsFavorite() : false)
                .build();

        try {
            Birthday updated = birthdayService.updateBirthday(id, birthdayDetails, user);
            return ResponseEntity.ok(mapToResponse(updated));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(new MessageResponse(e.getMessage()));
        }
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteBirthday(@PathVariable Long id, @AuthenticationPrincipal UserDetailsImpl userDetails) {
        User user = getAuthenticatedUser(userDetails);
        try {
            birthdayService.deleteBirthday(id, user);
            return ResponseEntity.ok(new MessageResponse("Birthday deleted successfully"));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(new MessageResponse(e.getMessage()));
        }
    }

    @GetMapping("/{id}/generate-gifts")
    public ResponseEntity<?> getGiftSuggestions(
            @PathVariable Long id,
            @RequestParam(defaultValue = "fr") String lang,
            @AuthenticationPrincipal UserDetailsImpl userDetails) {
        User user = getAuthenticatedUser(userDetails);
        
        return birthdayService.getBirthday(id, user).map(birthday -> {
            Integer age = null;
            if (birthday.getBirthdate() != null) {
                age = Period.between(birthday.getBirthdate(), LocalDate.now()).getYears();
            }
            
            app.time2wish.dto.GiftSuggestionResponse response;
            if (user.getPlan() == app.time2wish.model.PlanType.BASIC) {
                response = geminiService.generateLocalFallbackResponse(
                        birthday.getName(), age, birthday.getGender(), birthday.getCategory(), birthday.getInterests(), lang
                );
            } else {
                response = geminiService.generateGiftSuggestions(
                        birthday.getName(), age, birthday.getGender(), birthday.getCategory(), birthday.getInterests(), lang
                );
            }
            return ResponseEntity.ok(response);
        }).orElse(ResponseEntity.notFound().build());
    }

    /**
     * Manual trigger for birthday reminders – for development/testing purposes.
     * Requires authentication. Scans all active birthdays and sends reminder emails
     * for those whose reminder window matches today.
     */
    @PostMapping("/test-reminders")
    public ResponseEntity<Map<String, Object>> triggerReminders(
            @AuthenticationPrincipal UserDetailsImpl userDetails) {
        // Any authenticated user can trigger this for testing
        int count = reminderScheduler.triggerRemindersNow();
        return ResponseEntity.ok(Map.of(
            "message", count > 0
                ? count + " rappel(s) envoyé(s) avec succès ! Vérifiez le dossier scratch/emails/ pour les aperçus."
                : "Aucun anniversaire à rappeler aujourd'hui selon les fenêtres configurées.",
            "remindersProcessed", count
        ));
    }
}
