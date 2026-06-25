package app.time2wish.controller;

import app.time2wish.dto.GiftCreateDto;
import app.time2wish.dto.GiftDto;
import app.time2wish.dto.MessageResponse;
import app.time2wish.dto.ShareTokenDto;
import app.time2wish.model.User;
import app.time2wish.service.GiftService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import app.time2wish.security.UserDetailsImpl;
import app.time2wish.repository.UserRepository;

import java.util.List;

@RestController
@RequestMapping("/api/birthdays/{birthdayId}/gifts")
@RequiredArgsConstructor
public class GiftController {

    private final GiftService giftService;
    private final UserRepository userRepository;

    private User getAuthenticatedUser(UserDetailsImpl userDetails) {
        return userRepository.findById(userDetails.getId())
                .orElseThrow(() -> new RuntimeException("Error: Authenticated user not found in DB"));
    }

    @GetMapping
    public ResponseEntity<List<GiftDto>> getGifts(
            @PathVariable Long birthdayId,
            @AuthenticationPrincipal UserDetailsImpl userDetails) {
        return ResponseEntity.ok(giftService.getGiftsForBirthday(birthdayId, getAuthenticatedUser(userDetails)));
    }

    @PostMapping
    public ResponseEntity<GiftDto> addGift(
            @PathVariable Long birthdayId,
            @Valid @RequestBody GiftCreateDto dto,
            @AuthenticationPrincipal UserDetailsImpl userDetails) {
        return ResponseEntity.ok(giftService.addGift(birthdayId, getAuthenticatedUser(userDetails), dto));
    }

    @DeleteMapping("/{giftId}")
    public ResponseEntity<MessageResponse> removeGift(
            @PathVariable Long birthdayId,
            @PathVariable Long giftId,
            @AuthenticationPrincipal UserDetailsImpl userDetails) {
        giftService.removeGift(birthdayId, giftId, getAuthenticatedUser(userDetails));
        return ResponseEntity.ok(new MessageResponse("Gift removed successfully"));
    }

    @PostMapping("/share")
    public ResponseEntity<ShareTokenDto> generateShareToken(
            @PathVariable Long birthdayId,
            @AuthenticationPrincipal UserDetailsImpl userDetails) {
        String token = giftService.generateShareToken(birthdayId, getAuthenticatedUser(userDetails));
        return ResponseEntity.ok(new ShareTokenDto(token));
    }
}
