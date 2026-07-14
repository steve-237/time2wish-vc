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
import app.time2wish.service.IAService;
import app.time2wish.dto.GiftSuggestion;
import app.time2wish.dto.PartyTaskCreateDto;
import app.time2wish.dto.PartyTaskDto;
import app.time2wish.model.PartyTask;
import app.time2wish.repository.PartyTaskRepository;
import app.time2wish.repository.MemoryItemRepository;
import app.time2wish.repository.ECardSignatureRepository;
import app.time2wish.dto.MemoryItemDto;
import app.time2wish.dto.ECardSignatureDto;
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
    private IAService IAService;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private BirthdayReminderScheduler reminderScheduler;

    @Autowired
    private PartyTaskRepository partyTaskRepository;

    @Autowired
    private MemoryItemRepository memoryItemRepository;

    @Autowired
    private ECardSignatureRepository eCardSignatureRepository;

    private User getAuthenticatedUser(UserDetailsImpl userDetails) {
        return userRepository.findById(userDetails.getId())
                .orElseThrow(() -> new RuntimeException("Error: Authenticated user not found in DB"));
    }

    private BirthdayResponse mapToResponse(Birthday b) {
        java.util.List<app.time2wish.dto.PartyTaskDto> tasks = partyTaskRepository.findByBirthday(b).stream()
                .map(t -> app.time2wish.dto.PartyTaskDto.builder()
                        .id(t.getId())
                        .birthdayId(b.getId())
                        .description(t.getDescription())
                        .assigneeName(t.getAssigneeName())
                        .isCompleted(t.getIsCompleted())
                        .createdAt(t.getCreatedAt())
                        .build())
                .collect(Collectors.toList());

        List<MemoryItemDto> memories = memoryItemRepository.findByBirthdayOrderByCreatedAtDesc(b).stream()
                .map(MemoryItemDto::fromEntity)
                .collect(Collectors.toList());

        List<ECardSignatureDto> signatures = eCardSignatureRepository.findByBirthdayOrderByCreatedAtAsc(b).stream()
                .map(ECardSignatureDto::fromEntity)
                .collect(Collectors.toList());

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
                .partyDate(b.getPartyDate())
                .partyTime(b.getPartyTime())
                .partyLocation(b.getPartyLocation())
                .partyDescription(b.getPartyDescription())
                .shareToken(b.getShareToken())
                .partyTasks(tasks)
                .memories(memories)
                .signatures(signatures)
                .build();
    }

    private ResponseEntity<?> validateBirthdayLimits(BirthdayRequest request, User user, Long birthdayIdToUpdate) {
        // Validate reminders
        Short rDays = request.getReminderDays() != null ? request.getReminderDays() : (short) 0;
        if (user.getPlan() == app.time2wish.model.PlanType.BASIC && rDays > 0) {
            return ResponseEntity.status(403).body(new MessageResponse("BASIC plan can only set reminder for Day D (0)."));
        } else if (user.getPlan() == app.time2wish.model.PlanType.PLUS && rDays > 1) {
            return ResponseEntity.status(403).body(new MessageResponse("PLUS plan can only set reminder up to 1 day before."));
        }

        // Validate favorites
        if (request.getIsFavorite() != null && request.getIsFavorite() && user.getPlan() == app.time2wish.model.PlanType.BASIC) {
            long favCount = birthdayService.getActiveBirthdays(user).stream()
                .filter(b -> (b.getIsFavorite() != null && b.getIsFavorite()) && (birthdayIdToUpdate == null || !b.getId().equals(birthdayIdToUpdate)))
                .count();
            if (favCount >= 3) {
                return ResponseEntity.status(403).body(new MessageResponse("Plan limit reached (3 favorites max for BASIC)"));
            }
        }
        return null;
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
    public ResponseEntity<?> createBirthday(
            @Valid @RequestBody BirthdayRequest request,
            @AuthenticationPrincipal UserDetailsImpl userDetails) {
        User user = getAuthenticatedUser(userDetails);

        long currentCount = birthdayService.getActiveBirthdays(user).size();
        if (user.getPlan() == app.time2wish.model.PlanType.BASIC && currentCount >= 10) {
            return ResponseEntity.status(403).body(new MessageResponse("Plan limit reached (10 max for BASIC)"));
        } else if (user.getPlan() == app.time2wish.model.PlanType.PLUS && currentCount >= 50) {
            return ResponseEntity.status(403).body(new MessageResponse("Plan limit reached (50 max for PLUS)"));
        }

        ResponseEntity<?> validationError = validateBirthdayLimits(request, user, null);
        if (validationError != null) return validationError;

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
                .partyDate(request.getPartyDate())
                .partyTime(request.getPartyTime())
                .partyLocation(request.getPartyLocation())
                .partyDescription(request.getPartyDescription())
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

        ResponseEntity<?> validationError = validateBirthdayLimits(request, user, id);
        if (validationError != null) return validationError;

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
                .partyDate(request.getPartyDate())
                .partyTime(request.getPartyTime())
                .partyLocation(request.getPartyLocation())
                .partyDescription(request.getPartyDescription())
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

    @PostMapping("/{id}/tasks")
    public ResponseEntity<?> addPartyTask(
            @PathVariable Long id,
            @Valid @RequestBody PartyTaskCreateDto dto,
            @AuthenticationPrincipal UserDetailsImpl userDetails) {
        User user = getAuthenticatedUser(userDetails);
        
        Birthday birthday = birthdayService.getBirthday(id, user)
                .orElseThrow(() -> new RuntimeException("Birthday not found"));

        PartyTask task = PartyTask.builder()
                .birthday(birthday)
                .description(dto.getDescription())
                .build();
        
        task = partyTaskRepository.save(task);
        
        return ResponseEntity.status(201).body(app.time2wish.dto.PartyTaskDto.builder()
                .id(task.getId())
                .birthdayId(birthday.getId())
                .description(task.getDescription())
                .assigneeName(task.getAssigneeName())
                .isCompleted(task.getIsCompleted())
                .createdAt(task.getCreatedAt())
                .build());
    }

    @DeleteMapping("/{id}/tasks/{taskId}")
    public ResponseEntity<?> deletePartyTask(
            @PathVariable Long id,
            @PathVariable Long taskId,
            @AuthenticationPrincipal UserDetailsImpl userDetails) {
        User user = getAuthenticatedUser(userDetails);
        
        Birthday birthday = birthdayService.getBirthday(id, user)
                .orElseThrow(() -> new RuntimeException("Birthday not found"));

        PartyTask task = partyTaskRepository.findById(taskId)
                .orElseThrow(() -> new RuntimeException("Task not found"));

        if (!task.getBirthday().getId().equals(birthday.getId())) {
            return ResponseEntity.status(403).body(new MessageResponse("Task does not belong to this birthday"));
        }

        partyTaskRepository.delete(task);
        return ResponseEntity.ok(new MessageResponse("Task deleted successfully"));
    }

    @DeleteMapping("/{id}/memories/{memoryId}")
    public ResponseEntity<?> deleteMemory(
            @PathVariable Long id,
            @PathVariable Long memoryId,
            @AuthenticationPrincipal UserDetailsImpl userDetails) {
        User user = getAuthenticatedUser(userDetails);
        
        Birthday birthday = birthdayService.getBirthday(id, user)
                .orElseThrow(() -> new RuntimeException("Birthday not found"));

        app.time2wish.model.MemoryItem memory = memoryItemRepository.findById(memoryId)
                .orElseThrow(() -> new RuntimeException("Memory not found"));

        if (!memory.getBirthday().getId().equals(birthday.getId())) {
            return ResponseEntity.status(403).body(new MessageResponse("Memory does not belong to this birthday"));
        }

        memoryItemRepository.delete(memory);
        return ResponseEntity.ok(new MessageResponse("Memory deleted successfully"));
    }

    @DeleteMapping("/{id}/signatures/{signatureId}")
    public ResponseEntity<?> deleteSignature(
            @PathVariable Long id,
            @PathVariable Long signatureId,
            @AuthenticationPrincipal UserDetailsImpl userDetails) {
        User user = getAuthenticatedUser(userDetails);
        
        Birthday birthday = birthdayService.getBirthday(id, user)
                .orElseThrow(() -> new RuntimeException("Birthday not found"));

        app.time2wish.model.ECardSignature signature = eCardSignatureRepository.findById(signatureId)
                .orElseThrow(() -> new RuntimeException("Signature not found"));

        if (!signature.getBirthday().getId().equals(birthday.getId())) {
            return ResponseEntity.status(403).body(new MessageResponse("Signature does not belong to this birthday"));
        }

        eCardSignatureRepository.delete(signature);
        return ResponseEntity.ok(new MessageResponse("Signature deleted successfully"));
    }

    @GetMapping("/{id}/generate-gifts")
    public ResponseEntity<?> getGiftSuggestions(
            @PathVariable Long id,
            @RequestParam(defaultValue = "fr") String lang,
            @AuthenticationPrincipal UserDetailsImpl userDetails) {
        User user = getAuthenticatedUser(userDetails);
        
        if (user.getPlan() == app.time2wish.model.PlanType.BASIC) {
            if (user.getCoins() >= 20) {
                user.setCoins(user.getCoins() - 20);
                userRepository.save(user);
            } else {
                return ResponseEntity.status(403).body(new MessageResponse("La génération d'idées de cadeaux nécessite le forfait PREMIUM/PLUS, ou 20 WishCoins."));
            }
        } else if (user.getPlan() == app.time2wish.model.PlanType.PLUS) {
            java.time.LocalDateTime lastGen = user.getLastAiGiftGeneration();
            if (lastGen != null && lastGen.plusDays(30).isAfter(java.time.LocalDateTime.now())) {
                if (user.getCoins() >= 20) {
                    user.setCoins(user.getCoins() - 20);
                } else {
                    java.time.Duration duration = java.time.Duration.between(java.time.LocalDateTime.now(), lastGen.plusDays(30));
                    long days = duration.toDays();
                    return ResponseEntity.status(429).body(new MessageResponse(String.format("Prochaine génération gratuite dans %dj. (Ou utilisez 20 WishCoins)", days)));
                }
            }
            user.setLastAiGiftGeneration(java.time.LocalDateTime.now());
            userRepository.save(user);
        }
        
        return birthdayService.getBirthday(id, user).map(birthday -> {
            Integer age = null;
            if (birthday.getBirthdate() != null) {
                age = Period.between(birthday.getBirthdate(), LocalDate.now()).getYears();
            }
            
            app.time2wish.dto.GiftSuggestionResponse response = IAService.generateGiftSuggestions(
                    birthday.getName(), age, birthday.getGender(), birthday.getCategory(), birthday.getInterests(), lang
            );
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
