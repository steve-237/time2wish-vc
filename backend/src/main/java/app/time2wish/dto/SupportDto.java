package app.time2wish.dto;

import lombok.Data;

public class SupportDto {

    @Data
    public static class CreateTicketRequest {
        private String subject;
        private String message;
    }

    @Data
    public static class ReplyTicketRequest {
        private String replyMessage;
    }

    @Data
    public static class UpdateStatusRequest {
        private String status;
    }
}
