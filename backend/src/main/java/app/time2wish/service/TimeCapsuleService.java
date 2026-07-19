package app.time2wish.service;

import app.time2wish.dto.TimeCapsuleResponseDto;
import app.time2wish.dto.TimeCapsuleVideoDto;
import app.time2wish.model.Birthday;
import app.time2wish.model.TimeCapsuleVideo;
import app.time2wish.repository.BirthdayRepository;
import app.time2wish.repository.TimeCapsuleVideoRepository;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.Collections;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class TimeCapsuleService {

    private final TimeCapsuleVideoRepository timeCapsuleVideoRepository;
    private final BirthdayRepository birthdayRepository;

    @Value("${app.upload.dir:uploads/videos}")
    private String uploadDir;

    public TimeCapsuleService(TimeCapsuleVideoRepository timeCapsuleVideoRepository, BirthdayRepository birthdayRepository) {
        this.timeCapsuleVideoRepository = timeCapsuleVideoRepository;
        this.birthdayRepository = birthdayRepository;
    }

    public void uploadVideo(String token, String guestName, MultipartFile file) {
        Birthday birthday = birthdayRepository.findByShareTokenAndIsDeletedFalse(token)
                .orElseThrow(() -> new RuntimeException("Invalid share token"));

        if (file.isEmpty()) {
            throw new RuntimeException("File is empty");
        }

        try {
            Path uploadPath = Paths.get(uploadDir);
            if (!Files.exists(uploadPath)) {
                Files.createDirectories(uploadPath);
            }

            String filename = UUID.randomUUID().toString() + "_" + file.getOriginalFilename();
            Path filePath = uploadPath.resolve(filename);
            Files.copy(file.getInputStream(), filePath);

            TimeCapsuleVideo video = TimeCapsuleVideo.builder()
                    .birthday(birthday)
                    .guestName(guestName)
                    .videoUrl("/uploads/videos/" + filename) // Endpoint that will serve the file
                    .isViewed(false)
                    .build();

            timeCapsuleVideoRepository.save(video);
        } catch (IOException e) {
            throw new RuntimeException("Could not store file", e);
        }
    }

    public TimeCapsuleResponseDto getCapsuleStatus(Long birthdayId, Long userId) {
        Birthday birthday = birthdayRepository.findById(birthdayId)
                .orElseThrow(() -> new RuntimeException("Birthday not found"));

        if (!birthday.getUser().getId().equals(userId)) {
            throw new RuntimeException("Unauthorized");
        }

        LocalDate today = LocalDate.now();
        LocalDate nextBirthdayDate = birthday.getBirthdate().withYear(today.getYear());
        
        if (nextBirthdayDate.isBefore(today) || nextBirthdayDate.isEqual(today)) {
            // Already happened this year
            if (nextBirthdayDate.isBefore(today)) {
                // If the birthday is passed, is it fully unlocked for the current year? 
                // Usually yes, it unlocks on the day and stays unlocked.
            }
        } else {
            // Future birthday this year
            long daysRemaining = ChronoUnit.DAYS.between(today, nextBirthdayDate);
            return TimeCapsuleResponseDto.builder()
                    .status("LOCKED")
                    .daysRemaining((int) daysRemaining)
                    .videos(Collections.emptyList())
                    .build();
        }

        List<TimeCapsuleVideo> videos = timeCapsuleVideoRepository.findByBirthdayIdOrderByCreatedAtDesc(birthdayId);
        List<TimeCapsuleVideoDto> dtos = videos.stream()
                .filter(v -> !v.getIsViewed()) // Only return unviewed
                .map(v -> TimeCapsuleVideoDto.builder()
                        .id(v.getId())
                        .guestName(v.getGuestName())
                        .videoUrl(v.getVideoUrl())
                        .isViewed(v.getIsViewed())
                        .createdAt(v.getCreatedAt())
                        .build())
                .collect(Collectors.toList());

        return TimeCapsuleResponseDto.builder()
                .status("UNLOCKED")
                .daysRemaining(null)
                .videos(dtos)
                .build();
    }

    public void markAsViewed(Long birthdayId, Long videoId, Long userId) {
        Birthday birthday = birthdayRepository.findById(birthdayId)
                .orElseThrow(() -> new RuntimeException("Birthday not found"));

        if (!birthday.getUser().getId().equals(userId)) {
            throw new RuntimeException("Unauthorized");
        }

        TimeCapsuleVideo video = timeCapsuleVideoRepository.findById(videoId)
                .orElseThrow(() -> new RuntimeException("Video not found"));

        if (!video.getBirthday().getId().equals(birthdayId)) {
            throw new RuntimeException("Video does not belong to this birthday");
        }

        // Delete physical file
        try {
            String filename = video.getVideoUrl().replace("/uploads/videos/", "");
            Path filePath = Paths.get(uploadDir).resolve(filename);
            Files.deleteIfExists(filePath);
        } catch (IOException e) {
            System.err.println("Failed to delete video file: " + e.getMessage());
        }

        video.setIsViewed(true);
        video.setVideoUrl(""); // clear URL
        timeCapsuleVideoRepository.save(video);
    }
}
