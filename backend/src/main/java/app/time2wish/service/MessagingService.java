package app.time2wish.service;

import app.time2wish.dto.ConversationDto;
import app.time2wish.dto.ConversationMemberDto;
import app.time2wish.dto.MessageDto;
import app.time2wish.model.*;
import app.time2wish.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class MessagingService {

    private final ConversationRepository conversationRepository;
    private final ConversationMemberRepository memberRepository;
    private final MessageRepository messageRepository;
    private final UserRepository userRepository;
    private final ContactService contactService;
    private final BirthdayRepository birthdayRepository;

    @Transactional
    public ConversationDto createPrivateConversation(Long userId, Long contactUserId) {
        if (!contactService.areContacts(userId, contactUserId)) {
            throw new IllegalArgumentException("Users are not contacts");
        }

        Conversation existing = conversationRepository.findPrivateConversation(userId, contactUserId).orElse(null);
        if (existing != null) {
            return toConversationDto(existing, userId);
        }

        User u1 = userRepository.findById(userId).orElseThrow();
        User u2 = userRepository.findById(contactUserId).orElseThrow();

        Conversation conversation = Conversation.builder()
                .type(ConversationType.PRIVATE)
                .creator(u1)
                .build();
        
        conversation = conversationRepository.save(conversation);

        ConversationMember m1 = ConversationMember.builder()
                .conversation(conversation)
                .user(u1)
                .role(MemberRole.ADMIN)
                .build();
        ConversationMember m2 = ConversationMember.builder()
                .conversation(conversation)
                .user(u2)
                .role(MemberRole.MEMBER)
                .build();
        
        memberRepository.saveAll(List.of(m1, m2));
        
        // Refresh
        conversation.setMembers(List.of(m1, m2));
        return toConversationDto(conversation, userId);
    }

    @Transactional
    public ConversationDto createGroupConversation(String name, Long creatorId, List<Long> memberIds) {
        User creator = userRepository.findById(creatorId).orElseThrow();
        
        // Plan checks
        if (creator.getPlan() == PlanType.BASIC) {
            throw new IllegalArgumentException("BASIC plan cannot create groups");
        }
        if (creator.getPlan() == PlanType.PLUS && memberIds.size() > 4) { // creator + 4 = 5 max
            throw new IllegalArgumentException("PLUS plan max 5 members");
        }

        Conversation conversation = Conversation.builder()
                .name(name)
                .type(ConversationType.GROUP)
                .creator(creator)
                .build();
                
        conversation = conversationRepository.save(conversation);
        
        List<ConversationMember> members = new ArrayList<>();
        members.add(ConversationMember.builder()
                .conversation(conversation)
                .user(creator)
                .role(MemberRole.ADMIN)
                .build());
                
        for (Long id : memberIds) {
            if (!id.equals(creatorId)) {
                User u = userRepository.findById(id).orElseThrow();
                members.add(ConversationMember.builder()
                        .conversation(conversation)
                        .user(u)
                        .role(MemberRole.MEMBER)
                        .build());
            }
        }
        
        memberRepository.saveAll(members);
        conversation.setMembers(members);
        return toConversationDto(conversation, creatorId);
    }

    @Transactional
    public ConversationDto createBirthdayGroup(Long birthdayId, Long creatorId, List<Long> memberIds) {
        Conversation existing = conversationRepository.findByBirthdayId(birthdayId).orElse(null);
        if (existing != null) {
            return toConversationDto(existing, creatorId);
        }

        Birthday b = birthdayRepository.findById(birthdayId).orElseThrow();
        String name = "🎂 Anniversaire de " + b.getName();

        User creator = userRepository.findById(creatorId).orElseThrow();
        
        // Plan checks
        if (creator.getPlan() == PlanType.BASIC) {
            throw new IllegalArgumentException("BASIC plan cannot create groups");
        }
        if (creator.getPlan() == PlanType.PLUS && memberIds.size() > 4) {
            throw new IllegalArgumentException("PLUS plan max 5 members");
        }

        Conversation conversation = Conversation.builder()
                .name(name)
                .type(ConversationType.GROUP)
                .birthday(b)
                .creator(creator)
                .build();
                
        conversation = conversationRepository.save(conversation);
        
        List<ConversationMember> members = new ArrayList<>();
        members.add(ConversationMember.builder()
                .conversation(conversation)
                .user(creator)
                .role(MemberRole.ADMIN)
                .build());
                
        for (Long id : memberIds) {
            if (!id.equals(creatorId)) {
                User u = userRepository.findById(id).orElseThrow();
                members.add(ConversationMember.builder()
                        .conversation(conversation)
                        .user(u)
                        .role(MemberRole.MEMBER)
                        .build());
            }
        }
        
        memberRepository.saveAll(members);
        conversation.setMembers(members);
        return toConversationDto(conversation, creatorId);
    }

    public List<ConversationDto> getConversations(Long userId) {
        return conversationRepository.findByMembersUserId(userId).stream()
                .map(c -> toConversationDto(c, userId))
                .collect(Collectors.toList());
    }

    public List<MessageDto> getMessages(Long conversationId, Long userId) {
        memberRepository.findByConversationIdAndUserId(conversationId, userId).orElseThrow();
        return messageRepository.findByConversationIdOrderByCreatedAtAsc(conversationId).stream()
                .map(this::toMessageDto)
                .collect(Collectors.toList());
    }

    @Transactional
    public MessageDto sendMessage(Long conversationId, Long senderId, String content) {
        ConversationMember member = memberRepository.findByConversationIdAndUserId(conversationId, senderId).orElseThrow();
        Conversation conversation = member.getConversation();
        User sender = member.getUser();

        Message msg = Message.builder()
                .conversation(conversation)
                .sender(sender)
                .content(content)
                .build();
                
        msg = messageRepository.save(msg);
        
        conversation.setUpdatedAt(LocalDateTime.now());
        conversationRepository.save(conversation);
        
        // Mark as read for the sender
        member.setLastReadAt(LocalDateTime.now());
        memberRepository.save(member);
        
        return toMessageDto(msg);
    }

    @Transactional
    public ConversationDto addMember(Long conversationId, Long adminId, Long newMemberId) {
        ConversationMember admin = memberRepository.findByConversationIdAndUserId(conversationId, adminId).orElseThrow();
        if (admin.getRole() != MemberRole.ADMIN) {
            throw new IllegalArgumentException("Only admins can add members");
        }
        
        Conversation c = admin.getConversation();
        if (c.getType() != ConversationType.GROUP) {
            throw new IllegalArgumentException("Can only add members to group conversations");
        }
        
        // Plan checks
        if (c.getCreator().getPlan() == PlanType.PLUS && c.getMembers().size() >= 5) {
            throw new IllegalArgumentException("PLUS plan max 5 members");
        }
        
        User newUser = userRepository.findById(newMemberId).orElseThrow();
        ConversationMember newMember = ConversationMember.builder()
                .conversation(c)
                .user(newUser)
                .build();
                
        memberRepository.save(newMember);
        return toConversationDto(c, adminId);
    }

    @Transactional
    public void removeMember(Long conversationId, Long adminId, Long memberId) {
        ConversationMember admin = memberRepository.findByConversationIdAndUserId(conversationId, adminId).orElseThrow();
        if (admin.getRole() != MemberRole.ADMIN && !adminId.equals(memberId)) {
            throw new IllegalArgumentException("Only admins can remove other members");
        }
        ConversationMember toRemove = memberRepository.findByConversationIdAndUserId(conversationId, memberId).orElseThrow();
        memberRepository.delete(toRemove);
    }

    @Transactional
    public void markAsRead(Long conversationId, Long userId) {
        ConversationMember m = memberRepository.findByConversationIdAndUserId(conversationId, userId).orElseThrow();
        m.setLastReadAt(LocalDateTime.now());
        memberRepository.save(m);
    }

    public int getUnreadCount(Long userId) {
        int count = 0;
        List<ConversationMember> memberships = memberRepository.findByUserId(userId);
        for (ConversationMember m : memberships) {
            Long unread = messageRepository.countByConversationIdAndCreatedAtAfter(m.getConversation().getId(), m.getLastReadAt());
            if (unread > 0) count++;
        }
        return count;
    }

    private ConversationDto toConversationDto(Conversation c, Long userId) {
        String name = c.getName();
        if (c.getType() == ConversationType.PRIVATE) {
            ConversationMember other = c.getMembers().stream().filter(m -> !m.getUser().getId().equals(userId)).findFirst().orElse(null);
            if (other != null) {
                name = other.getUser().getFullName();
            }
        }
        
        List<ConversationMemberDto> members = c.getMembers().stream().map(m -> ConversationMemberDto.builder()
                .userId(m.getUser().getId())
                .fullName(m.getUser().getFullName())
                .avatarUrl(m.getUser().getAvatarUrl())
                .role(m.getRole().name())
                .joinedAt(m.getJoinedAt())
                .build()).collect(Collectors.toList());
                
        Message lastMessage = messageRepository.findFirstByConversationIdOrderByCreatedAtDesc(c.getId()).orElse(null);
        String lastMsgContent = lastMessage != null ? lastMessage.getContent() : null;
        LocalDateTime lastMsgAt = lastMessage != null ? lastMessage.getCreatedAt() : null;
        
        ConversationMember me = c.getMembers().stream().filter(m -> m.getUser().getId().equals(userId)).findFirst().orElse(null);
        int unread = 0;
        if (me != null && lastMessage != null) {
            unread = messageRepository.countByConversationIdAndCreatedAtAfter(c.getId(), me.getLastReadAt()).intValue();
        }
                
        return ConversationDto.builder()
                .id(c.getId())
                .name(name)
                .type(c.getType().name())
                .birthdayId(c.getBirthday() != null ? c.getBirthday().getId() : null)
                .members(members)
                .lastMessage(lastMsgContent)
                .lastMessageAt(lastMsgAt)
                .unreadCount(unread)
                .build();
    }

    private MessageDto toMessageDto(Message m) {
        return MessageDto.builder()
                .id(m.getId())
                .conversationId(m.getConversation().getId())
                .senderId(m.getSender().getId())
                .senderName(m.getSender().getFullName())
                .senderAvatar(m.getSender().getAvatarUrl())
                .content(m.getContent())
                .createdAt(m.getCreatedAt())
                .build();
    }
}
