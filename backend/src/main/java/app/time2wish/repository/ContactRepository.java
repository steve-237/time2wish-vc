package app.time2wish.repository;

import app.time2wish.model.Contact;
import app.time2wish.model.ContactStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ContactRepository extends JpaRepository<Contact, Long> {
    List<Contact> findByReceiverIdAndStatus(Long receiverId, ContactStatus status);
    List<Contact> findByRequesterIdAndStatus(Long requesterId, ContactStatus status);
    Optional<Contact> findByRequesterIdAndReceiverId(Long requesterId, Long receiverId);

    @Query("SELECT c FROM Contact c WHERE (c.requester.id = :userId OR c.receiver.id = :userId) AND c.status = 'ACCEPTED'")
    List<Contact> findAcceptedContacts(@Param("userId") Long userId);
}
