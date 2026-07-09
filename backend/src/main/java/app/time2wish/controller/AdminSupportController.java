package app.time2wish.controller;

import app.time2wish.dto.SupportDto;
import app.time2wish.model.SupportTicket;
import app.time2wish.service.SupportService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/admin/support")
@PreAuthorize("hasRole('ADMIN') or hasRole('SUPERADMIN')")
public class AdminSupportController {

    private final SupportService supportService;

    @Autowired
    public AdminSupportController(SupportService supportService) {
        this.supportService = supportService;
    }

    @GetMapping
    public ResponseEntity<?> getAllTickets() {
        List<SupportTicket> tickets = supportService.getAllTickets();
        return ResponseEntity.ok(tickets);
    }

    @PutMapping("/{id}/reply")
    public ResponseEntity<?> replyToTicket(@PathVariable Long id, @RequestBody SupportDto.ReplyTicketRequest request) {
        try {
            SupportTicket ticket = supportService.replyToTicket(id, request);
            return ResponseEntity.ok(ticket);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    @PutMapping("/{id}/status")
    public ResponseEntity<?> updateStatus(@PathVariable Long id, @RequestBody SupportDto.UpdateStatusRequest request) {
        try {
            SupportTicket ticket = supportService.updateTicketStatus(id, request.getStatus());
            return ResponseEntity.ok(ticket);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
}
