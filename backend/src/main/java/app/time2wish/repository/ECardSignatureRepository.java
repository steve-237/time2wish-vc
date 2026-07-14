package app.time2wish.repository;

import app.time2wish.model.Birthday;
import app.time2wish.model.ECardSignature;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ECardSignatureRepository extends JpaRepository<ECardSignature, Long> {
    List<ECardSignature> findByBirthdayOrderByCreatedAtAsc(Birthday birthday);
}
