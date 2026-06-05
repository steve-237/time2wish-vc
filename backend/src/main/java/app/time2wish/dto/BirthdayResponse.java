package app.time2wish.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.Setter;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Getter
@Setter
@AllArgsConstructor
@Builder
public class BirthdayResponse {
    private Long id;
    private String name;
    private LocalDate birthdate;
    private String category;
    private String photoUrl;
    private String notes;
    private Short reminderDays;
    private Boolean showAge;
    private String email;
    private String whatsapp;
    private String gender;
    private Boolean isDeleted;
    private LocalDateTime createdAt;
    private java.util.List<String> interests;
}
