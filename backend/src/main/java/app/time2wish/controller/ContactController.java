package app.time2wish.controller;

import app.time2wish.dto.ContactDto;
import app.time2wish.dto.UserSearchDto;
import app.time2wish.security.UserDetailsImpl;
import app.time2wish.service.ContactService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/contacts")
@RequiredArgsConstructor
public class ContactController {

    private final ContactService contactService;

    @GetMapping
    public ResponseEntity<List<ContactDto>> getContacts(@AuthenticationPrincipal UserDetailsImpl userDetails) {
        return ResponseEntity.ok(contactService.getContacts(userDetails.getId()));
    }

    @GetMapping("/pending")
    public ResponseEntity<List<ContactDto>> getPendingRequests(@AuthenticationPrincipal UserDetailsImpl userDetails) {
        return ResponseEntity.ok(contactService.getPendingRequests(userDetails.getId()));
    }

    @GetMapping("/search")
    public ResponseEntity<List<UserSearchDto>> searchUsers(
            @RequestParam String q,
            @AuthenticationPrincipal UserDetailsImpl userDetails) {
        return ResponseEntity.ok(contactService.searchUsers(q, userDetails.getId()));
    }

    @PostMapping("/request/{userId}")
    public ResponseEntity<ContactDto> sendRequest(
            @PathVariable Long userId,
            @AuthenticationPrincipal UserDetailsImpl userDetails) {
        return ResponseEntity.ok(contactService.sendRequest(userDetails.getId(), userId));
    }

    @PutMapping("/{id}/accept")
    public ResponseEntity<ContactDto> acceptRequest(
            @PathVariable Long id,
            @AuthenticationPrincipal UserDetailsImpl userDetails) {
        return ResponseEntity.ok(contactService.acceptRequest(id, userDetails.getId()));
    }

    @PutMapping("/{id}/reject")
    public ResponseEntity<ContactDto> rejectRequest(
            @PathVariable Long id,
            @AuthenticationPrincipal UserDetailsImpl userDetails) {
        return ResponseEntity.ok(contactService.rejectRequest(id, userDetails.getId()));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> removeContact(
            @PathVariable Long id,
            @AuthenticationPrincipal UserDetailsImpl userDetails) {
        contactService.removeContact(id, userDetails.getId());
        return ResponseEntity.ok().build();
    }
}
