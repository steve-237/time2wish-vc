package app.time2wish.service;

import app.time2wish.dto.*;
import app.time2wish.model.Birthday;
import app.time2wish.model.Gift;
import app.time2wish.model.GiftVote;
import app.time2wish.model.PartyTask;
import app.time2wish.repository.BirthdayRepository;
import app.time2wish.repository.GiftRepository;
import app.time2wish.repository.GiftVoteRepository;
import app.time2wish.repository.PartyTaskRepository;
import app.time2wish.repository.MemoryItemRepository;
import app.time2wish.repository.ECardSignatureRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class SharedListService {

    private final BirthdayRepository birthdayRepository;
    private final GiftRepository giftRepository;
    private final GiftService giftService;
    private final GiftVoteRepository giftVoteRepository;
    private final PartyTaskRepository partyTaskRepository;
    private final MemoryItemRepository memoryItemRepository;
    private final ECardSignatureRepository eCardSignatureRepository;

    public SharedBirthdayDto getSharedBirthday(String token, String voterSessionId) {
        Birthday birthday = birthdayRepository.findByShareTokenAndIsDeletedFalse(token)
                .orElseThrow(() -> new RuntimeException("Shared list not found or expired"));

        List<GiftDto> gifts = giftRepository.findByBirthdayId(birthday.getId()).stream()
                .map(g -> giftService.mapToDto(g, voterSessionId))
                .collect(Collectors.toList());

        List<PartyTaskDto> tasks = partyTaskRepository.findByBirthday(birthday).stream()
                .map(t -> PartyTaskDto.builder()
                        .id(t.getId())
                        .birthdayId(t.getBirthday().getId())
                        .description(t.getDescription())
                        .assigneeName(t.getAssigneeName())
                        .isCompleted(t.getIsCompleted())
                        .createdAt(t.getCreatedAt())
                        .build())
                .collect(Collectors.toList());

        List<MemoryItemDto> memories = memoryItemRepository.findByBirthdayOrderByCreatedAtDesc(birthday).stream()
                .map(MemoryItemDto::fromEntity)
                .collect(Collectors.toList());

        List<ECardSignatureDto> signatures = eCardSignatureRepository.findByBirthdayOrderByCreatedAtAsc(birthday).stream()
                .map(ECardSignatureDto::fromEntity)
                .collect(Collectors.toList());

        return SharedBirthdayDto.builder()
                .id(birthday.getId())
                .name(birthday.getName())
                .birthdate(birthday.getBirthdate())
                .showAge(birthday.getShowAge())
                .gender(birthday.getGender())
                .gifts(gifts)
                .partyDate(birthday.getPartyDate())
                .partyTime(birthday.getPartyTime())
                .partyLocation(birthday.getPartyLocation())
                .partyDescription(birthday.getPartyDescription())
                .partyTasks(tasks)
                .memories(memories)
                .signatures(signatures)
                .build();
    }

    public GiftDto reserveGift(String token, Long giftId, ReserveGiftDto dto) {
        Birthday birthday = birthdayRepository.findByShareTokenAndIsDeletedFalse(token)
                .orElseThrow(() -> new RuntimeException("Shared list not found or expired"));

        Gift gift = giftRepository.findById(giftId)
                .orElseThrow(() -> new RuntimeException("Gift not found"));

        if (!gift.getBirthday().getId().equals(birthday.getId())) {
            throw new RuntimeException("Gift does not belong to this shared list");
        }

        if (gift.getIsReserved()) {
            throw new RuntimeException("Gift is already reserved");
        }

        gift.setIsReserved(true);
        gift.setReservedByName(dto.getGuestName());
        gift = giftRepository.save(gift);

        return giftService.mapToDto(gift, null);
    }

    public GiftDto voteGift(String token, Long giftId, GiftVoteDto dto) {
        Birthday birthday = birthdayRepository.findByShareTokenAndIsDeletedFalse(token)
                .orElseThrow(() -> new RuntimeException("Shared list not found or expired"));

        Gift gift = giftRepository.findById(giftId)
                .orElseThrow(() -> new RuntimeException("Gift not found"));

        if (!gift.getBirthday().getId().equals(birthday.getId())) {
            throw new RuntimeException("Gift does not belong to this shared list");
        }

        Optional<GiftVote> existingVote = giftVoteRepository.findByGiftAndVoterSessionId(gift, dto.getVoterSessionId());

        if (dto.getVoteType() == null || dto.getVoteType().isEmpty()) {
            // Remove vote
            existingVote.ifPresent(giftVoteRepository::delete);
        } else {
            GiftVote.VoteType type = GiftVote.VoteType.valueOf(dto.getVoteType().toUpperCase());
            if (existingVote.isPresent()) {
                GiftVote vote = existingVote.get();
                vote.setVoteType(type);
                vote.setVoterName(dto.getVoterName());
                giftVoteRepository.save(vote);
            } else {
                GiftVote vote = GiftVote.builder()
                        .gift(gift)
                        .voterName(dto.getVoterName())
                        .voterSessionId(dto.getVoterSessionId())
                        .voteType(type)
                        .build();
                giftVoteRepository.save(vote);
            }
        }

        return giftService.mapToDto(gift, dto.getVoterSessionId());
    }

    public PartyTaskDto assignTask(String token, Long taskId, AssignTaskDto dto) {
        Birthday birthday = birthdayRepository.findByShareTokenAndIsDeletedFalse(token)
                .orElseThrow(() -> new RuntimeException("Shared list not found or expired"));

        PartyTask task = partyTaskRepository.findById(taskId)
                .orElseThrow(() -> new RuntimeException("Task not found"));

        if (!task.getBirthday().getId().equals(birthday.getId())) {
            throw new RuntimeException("Task does not belong to this shared list");
        }

        if (task.getAssigneeSessionId() != null && !task.getAssigneeSessionId().equals(dto.getGuestSessionId())) {
            throw new RuntimeException("Task is already assigned to someone else");
        }

        task.setAssigneeName(dto.getGuestName());
        task.setAssigneeSessionId(dto.getGuestSessionId());
        task = partyTaskRepository.save(task);

        return PartyTaskDto.builder()
                .id(task.getId())
                .birthdayId(task.getBirthday().getId())
                .description(task.getDescription())
                .assigneeName(task.getAssigneeName())
                .isCompleted(task.getIsCompleted())
                .createdAt(task.getCreatedAt())
                .build();
    }

    public PartyTaskDto unassignTask(String token, Long taskId, String sessionId) {
        Birthday birthday = birthdayRepository.findByShareTokenAndIsDeletedFalse(token)
                .orElseThrow(() -> new RuntimeException("Shared list not found or expired"));

        PartyTask task = partyTaskRepository.findById(taskId)
                .orElseThrow(() -> new RuntimeException("Task not found"));

        if (!task.getBirthday().getId().equals(birthday.getId())) {
            throw new RuntimeException("Task does not belong to this shared list");
        }

        if (!sessionId.equals(task.getAssigneeSessionId())) {
            throw new RuntimeException("You can only unassign yourself");
        }

        task.setAssigneeName(null);
        task.setAssigneeSessionId(null);
        task = partyTaskRepository.save(task);

        return PartyTaskDto.builder()
                .id(task.getId())
                .birthdayId(task.getBirthday().getId())
                .description(task.getDescription())
                .assigneeName(task.getAssigneeName())
                .isCompleted(task.getIsCompleted())
                .createdAt(task.getCreatedAt())
                .build();
    }

    public MemoryItemDto addMemory(String token, AddMemoryDto dto) {
        Birthday birthday = birthdayRepository.findByShareTokenAndIsDeletedFalse(token)
                .orElseThrow(() -> new RuntimeException("Shared list not found or expired"));

        app.time2wish.model.MemoryItem memory = app.time2wish.model.MemoryItem.builder()
                .birthday(birthday)
                .guestName(dto.getGuestName())
                .guestSessionId(dto.getGuestSessionId())
                .message(dto.getMessage())
                .mediaUrl(dto.getMediaUrl())
                .mediaType(dto.getMediaType())
                .build();

        return MemoryItemDto.fromEntity(memoryItemRepository.save(memory));
    }

    public ECardSignatureDto addSignature(String token, AddSignatureDto dto) {
        Birthday birthday = birthdayRepository.findByShareTokenAndIsDeletedFalse(token)
                .orElseThrow(() -> new RuntimeException("Shared list not found or expired"));

        app.time2wish.model.ECardSignature signature = app.time2wish.model.ECardSignature.builder()
                .birthday(birthday)
                .guestName(dto.getGuestName())
                .guestSessionId(dto.getGuestSessionId())
                .message(dto.getMessage())
                .color(dto.getColor())
                .fontFamily(dto.getFontFamily())
                .build();

        return ECardSignatureDto.fromEntity(eCardSignatureRepository.save(signature));
    }
}
