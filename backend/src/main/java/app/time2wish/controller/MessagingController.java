package app.time2wish.controller;

import app.time2wish.dto.ConversationDto;
import app.time2wish.dto.CreateGroupRequest;
import app.time2wish.dto.MessageDto;
import app.time2wish.dto.SendMessageRequest;
import app.time2wish.security.UserDetailsImpl;
import app.time2wish.service.MessagingService;
import app.time2wish.service.SettingService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.messaging.simp.SimpMessageHeaderAccessor;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

@RestController
@RequestMapping("/api/messaging")
@RequiredArgsConstructor
public class MessagingController {

    private final MessagingService messagingService;
    private final SimpMessagingTemplate messagingTemplate;
    private final SettingService settingService;

    private void checkModuleEnabled() {
        if (!settingService.getBooleanSetting(SettingService.MODULE_CHAT_ENABLED)) {
            throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE, "Chat module is disabled.");
        }
    }

    @GetMapping("/conversations")
    public ResponseEntity<List<ConversationDto>> getConversations(@AuthenticationPrincipal UserDetailsImpl userDetails) {
        checkModuleEnabled();
        return ResponseEntity.ok(messagingService.getConversations(userDetails.getId()));
    }

    @PostMapping("/conversations/private/{contactUserId}")
    public ResponseEntity<ConversationDto> createPrivateConversation(
            @PathVariable Long contactUserId,
            @AuthenticationPrincipal UserDetailsImpl userDetails) {
        checkModuleEnabled();
        return ResponseEntity.ok(messagingService.createPrivateConversation(userDetails.getId(), contactUserId));
    }

    @PostMapping("/conversations/group")
    public ResponseEntity<ConversationDto> createGroupConversation(
            @RequestBody CreateGroupRequest request,
            @AuthenticationPrincipal UserDetailsImpl userDetails) {
        checkModuleEnabled();
        return ResponseEntity.ok(messagingService.createGroupConversation(request.getName(), userDetails.getId(), request.getMemberIds()));
    }

    @PostMapping("/conversations/birthday/{birthdayId}")
    public ResponseEntity<ConversationDto> createBirthdayGroup(
            @PathVariable Long birthdayId,
            @RequestBody CreateGroupRequest request,
            @AuthenticationPrincipal UserDetailsImpl userDetails) {
        checkModuleEnabled();
        return ResponseEntity.ok(messagingService.createBirthdayGroup(birthdayId, userDetails.getId(), request.getMemberIds()));
    }

    @GetMapping("/conversations/{id}/messages")
    public ResponseEntity<List<MessageDto>> getMessages(
            @PathVariable Long id,
            @AuthenticationPrincipal UserDetailsImpl userDetails) {
        checkModuleEnabled();
        return ResponseEntity.ok(messagingService.getMessages(id, userDetails.getId()));
    }

    @PostMapping("/conversations/{id}/members/{userId}")
    public ResponseEntity<ConversationDto> addMember(
            @PathVariable Long id,
            @PathVariable Long userId,
            @AuthenticationPrincipal UserDetailsImpl userDetails) {
        checkModuleEnabled();
        return ResponseEntity.ok(messagingService.addMember(id, userDetails.getId(), userId));
    }

    @DeleteMapping("/conversations/{id}/members/{userId}")
    public ResponseEntity<Void> removeMember(
            @PathVariable Long id,
            @PathVariable Long userId,
            @AuthenticationPrincipal UserDetailsImpl userDetails) {
        checkModuleEnabled();
        messagingService.removeMember(id, userDetails.getId(), userId);
        return ResponseEntity.ok().build();
    }

    @PutMapping("/conversations/{id}/read")
    public ResponseEntity<Void> markAsRead(
            @PathVariable Long id,
            @AuthenticationPrincipal UserDetailsImpl userDetails) {
        checkModuleEnabled();
        messagingService.markAsRead(id, userDetails.getId());
        return ResponseEntity.ok().build();
    }

    @GetMapping("/unread-count")
    public ResponseEntity<Integer> getUnreadCount(@AuthenticationPrincipal UserDetailsImpl userDetails) {
        if (!settingService.getBooleanSetting(SettingService.MODULE_CHAT_ENABLED)) {
            return ResponseEntity.ok(0);
        }
        return ResponseEntity.ok(messagingService.getUnreadCount(userDetails.getId()));
    }

    @MessageMapping("/chat.sendMessage")
    public void sendMessage(@Payload SendMessageRequest request, SimpMessageHeaderAccessor headerAccessor) {
        if (!settingService.getBooleanSetting(SettingService.MODULE_CHAT_ENABLED)) return;
        Authentication auth = (Authentication) headerAccessor.getUser();
        if (auth != null && auth.getPrincipal() instanceof UserDetailsImpl) {
            UserDetailsImpl userDetails = (UserDetailsImpl) auth.getPrincipal();
            MessageDto msg = messagingService.sendMessage(request.getConversationId(), userDetails.getId(), request.getContent());
            messagingTemplate.convertAndSend("/topic/conversation/" + request.getConversationId(), msg);
        }
    }
}
