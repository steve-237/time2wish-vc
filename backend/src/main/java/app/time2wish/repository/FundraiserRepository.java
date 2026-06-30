package app.time2wish.repository;

import app.time2wish.model.Fundraiser;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface FundraiserRepository extends JpaRepository<Fundraiser, Long> {
    Optional<Fundraiser> findByGiftId(Long giftId);
}
