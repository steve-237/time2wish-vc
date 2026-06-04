package app.time2wish.dto;

public class AiResponse {
    private String message;

    public AiResponse(String message) {
        this.message = message;
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }
}
