package app.time2wish.repository;

import app.time2wish.model.Conversation;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ConversationRepository extends JpaRepository<Conversation, Long> {
    @Query("SELECT DISTINCT c FROM Conversation c JOIN c.members m WHERE m.user.id = :userId ORDER BY c.updatedAt DESC")
    List<Conversation> findByMembersUserId(@Param("userId") Long userId);

    Optional<Conversation> findByBirthdayId(Long birthdayId);

    @Query("SELECT c FROM Conversation c WHERE c.type = 'PRIVATE' AND (SELECT COUNT(m) FROM ConversationMember m WHERE m.conversation = c AND m.user.id IN (:user1Id, :user2Id)) = 2 AND (SELECT COUNT(m) FROM ConversationMember m WHERE m.conversation = c) = 2")
    Optional<Conversation> findPrivateConversation(@Param("user1Id") Long user1Id, @Param("user2Id") Long user2Id);
}
