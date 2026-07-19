package app.time2wish.repository;

import app.time2wish.model.TimeCapsuleVideo;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface TimeCapsuleVideoRepository extends JpaRepository<TimeCapsuleVideo, Long> {
    List<TimeCapsuleVideo> findByBirthdayIdOrderByCreatedAtDesc(Long birthdayId);
}
