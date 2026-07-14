package app.time2wish.repository;

import app.time2wish.model.Birthday;
import app.time2wish.model.MemoryItem;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface MemoryItemRepository extends JpaRepository<MemoryItem, Long> {
    List<MemoryItem> findByBirthdayOrderByCreatedAtDesc(Birthday birthday);
}
