package app.time2wish.repository;

import app.time2wish.model.AILog;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

@Repository
public interface AILogRepository extends JpaRepository<AILog, Long> {

    @Query("SELECT new map(a.featureType as featureType, COUNT(a) as count) FROM AILog a WHERE a.createdAt >= :since GROUP BY a.featureType")
    List<Map<String, Object>> countStatsByFeatureSince(@Param("since") LocalDateTime since);

}
