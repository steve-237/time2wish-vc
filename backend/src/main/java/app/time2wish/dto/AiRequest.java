package app.time2wish.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public class AiRequest {

    @NotNull
    private Long birthdayId;

    @NotBlank
    private String tone;

    private String extraInstructions;

    private String lang;

    public Long getBirthdayId() {
        return birthdayId;
    }

    public void setBirthdayId(Long birthdayId) {
        this.birthdayId = birthdayId;
    }

    public String getTone() {
        return tone;
    }

    public void setTone(String tone) {
        this.tone = tone;
    }

    public String getExtraInstructions() {
        return extraInstructions;
    }

    public void setExtraInstructions(String extraInstructions) {
        this.extraInstructions = extraInstructions;
    }

    public String getLang() {
        return lang;
    }

    public void setLang(String lang) {
        this.lang = lang;
    }
}
