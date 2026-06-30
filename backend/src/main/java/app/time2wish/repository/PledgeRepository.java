package app.time2wish.repository;

import app.time2wish.model.Pledge;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface PledgeRepository extends JpaRepository<Pledge, Long> {
    List<Pledge> findByFundraiserIdOrderByCreatedAtDesc(Long fundraiserId);
}
