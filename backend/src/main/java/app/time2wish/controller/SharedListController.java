package app.time2wish.controller;

import app.time2wish.dto.GiftDto;
import app.time2wish.dto.GiftVoteDto;
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
    public ResponseEntity<SharedBirthdayDto> getSharedList(
            @PathVariable String token,
            @RequestParam(required = false) String sessionId) {
        return ResponseEntity.ok(sharedListService.getSharedBirthday(token, sessionId));
    }

    @PostMapping("/{token}/gifts/{giftId}/reserve")
    public ResponseEntity<GiftDto> reserveGift(
            @PathVariable String token,
            @PathVariable Long giftId,
            @Valid @RequestBody ReserveGiftDto dto) {
        return ResponseEntity.ok(sharedListService.reserveGift(token, giftId, dto));
    }

    @PostMapping("/{token}/gifts/{giftId}/vote")
    public ResponseEntity<GiftDto> voteGift(
            @PathVariable String token,
            @PathVariable Long giftId,
            @Valid @RequestBody GiftVoteDto dto) {
        return ResponseEntity.ok(sharedListService.voteGift(token, giftId, dto));
    }

    @PostMapping("/{token}/tasks/{taskId}/assign")
    public ResponseEntity<app.time2wish.dto.PartyTaskDto> assignTask(
            @PathVariable String token,
            @PathVariable Long taskId,
            @Valid @RequestBody app.time2wish.dto.AssignTaskDto dto) {
        return ResponseEntity.ok(sharedListService.assignTask(token, taskId, dto));
    }

    @PostMapping("/{token}/tasks/{taskId}/unassign")
    public ResponseEntity<app.time2wish.dto.PartyTaskDto> unassignTask(
            @PathVariable String token,
            @PathVariable Long taskId,
            @RequestParam String sessionId) {
        return ResponseEntity.ok(sharedListService.unassignTask(token, taskId, sessionId));
    }

    @PostMapping("/{token}/memories")
    public ResponseEntity<app.time2wish.dto.MemoryItemDto> addMemory(
            @PathVariable String token,
            @Valid @RequestBody app.time2wish.dto.AddMemoryDto dto) {
        return ResponseEntity.ok(sharedListService.addMemory(token, dto));
    }

    @PostMapping("/{token}/signatures")
    public ResponseEntity<app.time2wish.dto.ECardSignatureDto> addSignature(
            @PathVariable String token,
            @Valid @RequestBody app.time2wish.dto.AddSignatureDto dto) {
        return ResponseEntity.ok(sharedListService.addSignature(token, dto));
    }
}
