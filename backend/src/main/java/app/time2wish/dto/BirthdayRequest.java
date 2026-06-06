package app.time2wish.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.Setter;
import java.time.LocalDate;

@Getter
@Setter
public class BirthdayRequest {
    @NotBlank
    @Size(max = 150)
    private String name;

    @NotNull
    private LocalDate birthdate;

    @NotBlank
    @Size(max = 50)
    private String category;

    private String photoUrl;

    private String notes;

    private Short reminderDays = (short) 7;

    private Boolean showAge = true;

    @Size(max = 255)
    private String email;

    @Size(max = 50)
    private String whatsapp;

    @Size(max = 20)
    private String gender;

    private java.util.List<String> interests;

    private Boolean isFavorite = false;
}
