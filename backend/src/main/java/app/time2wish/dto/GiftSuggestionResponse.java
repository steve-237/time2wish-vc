package app.time2wish.dto;

import java.util.List;

public class GiftSuggestionResponse {
    private List<GiftSuggestion> suggestions;
    private String source; // "AI" or "LOCAL"

    public GiftSuggestionResponse() {
    }

    public GiftSuggestionResponse(List<GiftSuggestion> suggestions, String source) {
        this.suggestions = suggestions;
        this.source = source;
    }

    public List<GiftSuggestion> getSuggestions() {
        return suggestions;
    }

    public void setSuggestions(List<GiftSuggestion> suggestions) {
        this.suggestions = suggestions;
    }

    public String getSource() {
        return source;
    }

    public void setSource(String source) {
        this.source = source;
    }
}
