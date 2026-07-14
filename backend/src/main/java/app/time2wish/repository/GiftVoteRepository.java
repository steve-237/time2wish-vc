package app.time2wish.repository;

import app.time2wish.model.Gift;
import app.time2wish.model.GiftVote;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface GiftVoteRepository extends JpaRepository<GiftVote, Long> {
    List<GiftVote> findByGift(Gift gift);
    Optional<GiftVote> findByGiftAndVoterSessionId(Gift gift, String voterSessionId);
    void deleteByGift(Gift gift);
}
