package app.time2wish.service;

import app.time2wish.dto.SupportDto;
import app.time2wish.model.SupportTicket;
import app.time2wish.model.User;
import app.time2wish.repository.SupportTicketRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

@Service
public class SupportService {

    private final SupportTicketRepository supportTicketRepository;

    @Autowired
    public SupportService(SupportTicketRepository supportTicketRepository) {
        this.supportTicketRepository = supportTicketRepository;
    }

    public List<SupportTicket> getUserTickets(Long userId) {
        return supportTicketRepository.findByUserIdOrderByCreatedAtDesc(userId);
    }

    public List<SupportTicket> getAllTickets() {
        return supportTicketRepository.findAll(); // Could add pagination or sorting later
    }

    @Transactional
    public SupportTicket createTicket(User user, SupportDto.CreateTicketRequest request) {
        SupportTicket ticket = SupportTicket.builder()
                .user(user)
                .subject(request.getSubject())
                .message(request.getMessage())
                .build();
        return supportTicketRepository.save(ticket);
    }

    @Transactional
    public SupportTicket replyToTicket(Long ticketId, SupportDto.ReplyTicketRequest request) {
        SupportTicket ticket = supportTicketRepository.findById(ticketId)
                .orElseThrow(() -> new RuntimeException("Ticket not found"));
        
        ticket.setAdminReply(request.getReplyMessage());
        ticket.setRepliedAt(LocalDateTime.now());
        ticket.setStatus("RESOLVED"); // Auto-resolve on reply, or could keep it open depending on logic
        return supportTicketRepository.save(ticket);
    }

    @Transactional
    public SupportTicket updateTicketStatus(Long ticketId, String status) {
        SupportTicket ticket = supportTicketRepository.findById(ticketId)
                .orElseThrow(() -> new RuntimeException("Ticket not found"));
        
        ticket.setStatus(status);
        return supportTicketRepository.save(ticket);
    }
}
