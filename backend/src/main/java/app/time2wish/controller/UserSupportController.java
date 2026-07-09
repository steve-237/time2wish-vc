package app.time2wish.controller;

import app.time2wish.dto.SupportDto;
import app.time2wish.model.SupportTicket;
import app.time2wish.model.User;
import app.time2wish.repository.UserRepository;
import app.time2wish.security.UserDetailsImpl;
import app.time2wish.service.SupportService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/support")
public class UserSupportController {

    private final SupportService supportService;
    private final UserRepository userRepository;

    @Autowired
    public UserSupportController(SupportService supportService, UserRepository userRepository) {
        this.supportService = supportService;
        this.userRepository = userRepository;
    }

    private User getCurrentUser() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth != null && auth.getPrincipal() instanceof UserDetailsImpl userDetails) {
            return userRepository.findById(userDetails.getId()).orElse(null);
        }
        return null;
    }

    @GetMapping
    public ResponseEntity<?> getMyTickets() {
        User currentUser = getCurrentUser();
        if (currentUser == null) return ResponseEntity.status(401).build();

        List<SupportTicket> tickets = supportService.getUserTickets(currentUser.getId());
        return ResponseEntity.ok(tickets);
    }

    @PostMapping
    public ResponseEntity<?> createTicket(@RequestBody SupportDto.CreateTicketRequest request) {
        User currentUser = getCurrentUser();
        if (currentUser == null) return ResponseEntity.status(401).build();

        SupportTicket ticket = supportService.createTicket(currentUser, request);
        return ResponseEntity.ok(ticket);
    }
}
