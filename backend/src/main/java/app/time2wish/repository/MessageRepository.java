package app.time2wish.repository;

import app.time2wish.model.Message;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface MessageRepository extends JpaRepository<Message, Long> {
    List<Message> findByConversationIdOrderByCreatedAtAsc(Long conversationId);
    Optional<Message> findFirstByConversationIdOrderByCreatedAtDesc(Long conversationId);
    Long countByConversationIdAndCreatedAtAfter(Long conversationId, LocalDateTime after);
}
