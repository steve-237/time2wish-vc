package app.time2wish.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SharedBirthdayDto {
    private Long id;
    private String name;
    private LocalDate birthdate;
    private Boolean showAge;
    private String gender;
    private List<GiftDto> gifts;
    
    // Party Details
    private LocalDate partyDate;
    private String partyTime;
    private String partyLocation;
    private String partyDescription;
    
    // Party Tasks
    private List<PartyTaskDto> partyTasks;

    // Phase 3: Collaborative Features
    private List<MemoryItemDto> memories;
    private List<ECardSignatureDto> signatures;
}
