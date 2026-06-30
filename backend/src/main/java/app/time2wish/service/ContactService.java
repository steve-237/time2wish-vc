package app.time2wish.service;

import app.time2wish.dto.ContactDto;
import app.time2wish.dto.UserSearchDto;
import app.time2wish.model.Contact;
import app.time2wish.model.ContactStatus;
import app.time2wish.model.User;
import app.time2wish.repository.ContactRepository;
import app.time2wish.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ContactService {

    private final ContactRepository contactRepository;
    private final UserRepository userRepository;
    private final org.springframework.messaging.simp.SimpMessagingTemplate messagingTemplate;

    public List<UserSearchDto> searchUsers(String query, Long currentUserId) {
        if (query == null || query.trim().isEmpty()) {
            return List.of();
        }
        return userRepository.findByFullNameContainingIgnoreCaseOrEmailContainingIgnoreCase(query, query)
                .stream()
                .filter(u -> !u.getId().equals(currentUserId))
                .map(u -> UserSearchDto.builder()
                        .id(u.getId())
                        .fullName(u.getFullName())
                        .email(u.getEmail())
                        .avatarUrl(u.getAvatarUrl())
                        .build())
                .limit(20)
                .collect(Collectors.toList());
    }

    @Transactional
    public ContactDto sendRequest(Long requesterId, Long receiverId) {
        if (requesterId.equals(receiverId)) {
            throw new IllegalArgumentException("Cannot send a request to yourself");
        }
        if (contactRepository.findByRequesterIdAndReceiverId(requesterId, receiverId).isPresent() ||
            contactRepository.findByRequesterIdAndReceiverId(receiverId, requesterId).isPresent()) {
            throw new IllegalArgumentException("Contact request already exists");
        }

        User requester = userRepository.findById(requesterId).orElseThrow();
        User receiver = userRepository.findById(receiverId).orElseThrow();

        Contact contact = Contact.builder()
                .requester(requester)
                .receiver(receiver)
                .status(ContactStatus.PENDING)
                .build();

        ContactDto dto = toDto(contactRepository.save(contact), requesterId);
        messagingTemplate.convertAndSend("/topic/user." + receiverId + ".contacts", "NEW_REQUEST");
        return dto;
    }

    @Transactional
    public ContactDto acceptRequest(Long contactId, Long userId) {
        Contact contact = contactRepository.findById(contactId).orElseThrow();
        if (!contact.getReceiver().getId().equals(userId)) {
            throw new IllegalArgumentException("Only the receiver can accept the request");
        }
        contact.setStatus(ContactStatus.ACCEPTED);
        ContactDto dto = toDto(contactRepository.save(contact), userId);
        messagingTemplate.convertAndSend("/topic/user." + contact.getRequester().getId() + ".contacts", "REQUEST_ACCEPTED");
        return dto;
    }

    @Transactional
    public ContactDto rejectRequest(Long contactId, Long userId) {
        Contact contact = contactRepository.findById(contactId).orElseThrow();
        if (!contact.getReceiver().getId().equals(userId)) {
            throw new IllegalArgumentException("Only the receiver can reject the request");
        }
        contact.setStatus(ContactStatus.REJECTED);
        ContactDto dto = toDto(contactRepository.save(contact), userId);
        // Usually we don't notify the requester of a rejection to avoid hard feelings, but we can update their list
        messagingTemplate.convertAndSend("/topic/user." + contact.getRequester().getId() + ".contacts", "REQUEST_REJECTED");
        return dto;
    }

    public List<ContactDto> getContacts(Long userId) {
        return contactRepository.findAcceptedContacts(userId).stream()
                .map(c -> toDto(c, userId))
                .collect(Collectors.toList());
    }

    public List<ContactDto> getPendingRequests(Long userId) {
        return contactRepository.findByReceiverIdAndStatus(userId, ContactStatus.PENDING).stream()
                .map(c -> toDto(c, userId))
                .collect(Collectors.toList());
    }

    @Transactional
    public void removeContact(Long contactId, Long userId) {
        Contact contact = contactRepository.findById(contactId).orElseThrow();
        if (!contact.getRequester().getId().equals(userId) && !contact.getReceiver().getId().equals(userId)) {
            throw new IllegalArgumentException("Unauthorized");
        }
        contactRepository.delete(contact);
        Long otherUserId = contact.getRequester().getId().equals(userId) ? contact.getReceiver().getId() : contact.getRequester().getId();
        messagingTemplate.convertAndSend("/topic/user." + otherUserId + ".contacts", "CONTACT_REMOVED");
    }

    public boolean areContacts(Long userId1, Long userId2) {
        return contactRepository.findAcceptedContacts(userId1).stream()
                .anyMatch(c -> c.getRequester().getId().equals(userId2) || c.getReceiver().getId().equals(userId2));
    }

    private ContactDto toDto(Contact contact, Long currentUserId) {
        User otherUser = contact.getRequester().getId().equals(currentUserId) ? contact.getReceiver() : contact.getRequester();
        return ContactDto.builder()
                .id(contact.getId())
                .userId(otherUser.getId())
                .fullName(otherUser.getFullName())
                .email(otherUser.getEmail())
                .avatarUrl(otherUser.getAvatarUrl())
                .status(contact.getStatus().name())
                .createdAt(contact.getCreatedAt())
                .build();
    }
}
