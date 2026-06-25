package app.time2wish.controller;

import app.time2wish.dto.GiftDto;
import app.time2wish.dto.ReserveGiftDto;
import app.time2wish.dto.SharedBirthdayDto;
import app.time2wish.service.SharedListService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/public/shared")
@RequiredArgsConstructor
public class SharedListController {

    private final SharedListService sharedListService;

    @GetMapping("/{token}")
    public ResponseEntity<SharedBirthdayDto> getSharedList(@PathVariable String token) {
        return ResponseEntity.ok(sharedListService.getSharedBirthday(token));
    }

    @PostMapping("/{token}/gifts/{giftId}/reserve")
    public ResponseEntity<GiftDto> reserveGift(
            @PathVariable String token,
            @PathVariable Long giftId,
            @Valid @RequestBody ReserveGiftDto dto) {
        return ResponseEntity.ok(sharedListService.reserveGift(token, giftId, dto));
    }
}
