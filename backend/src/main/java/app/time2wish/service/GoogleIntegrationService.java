package app.time2wish.service;

import app.time2wish.model.User;
import app.time2wish.model.Birthday;
import app.time2wish.repository.UserRepository;
import com.google.api.client.googleapis.auth.oauth2.GoogleAuthorizationCodeFlow;
import com.google.api.client.googleapis.auth.oauth2.GoogleTokenResponse;
import com.google.api.client.googleapis.auth.oauth2.GoogleCredential;
import com.google.api.client.http.javanet.NetHttpTransport;
import com.google.api.client.json.gson.GsonFactory;
import com.google.api.services.calendar.CalendarScopes;
import com.google.api.services.people.v1.PeopleServiceScopes;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.time.LocalDateTime;
import java.util.Arrays;
import java.util.List;

@Service
public class GoogleIntegrationService {

    @Value("${GOOGLE_CLIENT_ID:}")
    private String clientId;

    @Value("${GOOGLE_CLIENT_SECRET:}")
    private String clientSecret;

    @Value("${GOOGLE_REDIRECT_URI:http://localhost:4200/oauth/callback}")
    private String redirectUri;

    @Autowired
    private UserRepository userRepository;

    private static final List<String> SCOPES = Arrays.asList(
            CalendarScopes.CALENDAR_EVENTS,
            PeopleServiceScopes.CONTACTS_READONLY
    );

    @Autowired
    private BirthdayService birthdayService;

    public String getAuthorizationUrl() {
        GoogleAuthorizationCodeFlow flow = new GoogleAuthorizationCodeFlow.Builder(
                new NetHttpTransport(),
                GsonFactory.getDefaultInstance(),
                clientId,
                clientSecret,
                SCOPES
        ).setAccessType("offline").setApprovalPrompt("force").build();

        return flow.newAuthorizationUrl().setRedirectUri(redirectUri).build();
    }

    public void exchangeCodeForToken(String code, User user) throws IOException {
        GoogleAuthorizationCodeFlow flow = new GoogleAuthorizationCodeFlow.Builder(
                new NetHttpTransport(),
                GsonFactory.getDefaultInstance(),
                clientId,
                clientSecret,
                SCOPES
        ).build();

        GoogleTokenResponse response = flow.newTokenRequest(code).setRedirectUri(redirectUri).execute();

        user.setGoogleAccessToken(response.getAccessToken());
        if (response.getRefreshToken() != null) {
            user.setGoogleRefreshToken(response.getRefreshToken());
        }
        user.setGoogleTokenExpiry(LocalDateTime.now().plusSeconds(response.getExpiresInSeconds()));
        userRepository.save(user);
    }

    private Credential getCredential(User user) {
        if (user.getGoogleAccessToken() == null) {
            throw new RuntimeException("User is not connected to Google.");
        }
        
        return new GoogleCredential.Builder()
                .setTransport(new NetHttpTransport())
                .setJsonFactory(GsonFactory.getDefaultInstance())
                .setClientSecrets(clientId, clientSecret)
                .build()
                .setAccessToken(user.getGoogleAccessToken())
                .setRefreshToken(user.getGoogleRefreshToken());
    }

    public int importContacts(User user) throws Exception {
        Credential credential = getCredential(user);
        com.google.api.services.people.v1.PeopleService peopleService = new com.google.api.services.people.v1.PeopleService.Builder(
                new NetHttpTransport(), GsonFactory.getDefaultInstance(), credential)
                .setApplicationName("Time2Wish")
                .build();
        
        com.google.api.services.people.v1.model.ListConnectionsResponse response = peopleService.people().connections()
                .list("people/me")
                .setPersonFields("names,emailAddresses,birthdays,photos")
                .setPageSize(1000)
                .execute();

        java.util.List<com.google.api.services.people.v1.model.Person> connections = response.getConnections();
        if (connections == null) return 0;

        int importedCount = 0;
        for (com.google.api.services.people.v1.model.Person person : connections) {
            if (person.getBirthdays() != null && !person.getBirthdays().isEmpty()) {
                var bday = person.getBirthdays().get(0).getDate();
                if (bday != null && bday.getMonth() != null && bday.getDay() != null) {
                    int year = bday.getYear() != null ? bday.getYear() : java.time.LocalDate.now().getYear();
                    java.time.LocalDate birthdate = java.time.LocalDate.of(year, bday.getMonth(), bday.getDay());
                    
                    String name = "Unknown";
                    if (person.getNames() != null && !person.getNames().isEmpty()) {
                        name = person.getNames().get(0).getDisplayName();
                    }

                    String email = null;
                    if (person.getEmailAddresses() != null && !person.getEmailAddresses().isEmpty()) {
                        email = person.getEmailAddresses().get(0).getValue();
                    }

                    String photoUrl = null;
                    if (person.getPhotos() != null && !person.getPhotos().isEmpty()) {
                        photoUrl = person.getPhotos().get(0).getUrl();
                    }

                    boolean exists = birthdayService.getActiveBirthdays(user).stream()
                            .anyMatch(b -> b.getName().equalsIgnoreCase(name) && b.getBirthdate().equals(birthdate));
                    
                    if (!exists) {
                        Birthday newBday = Birthday.builder()
                                .name(name)
                                .birthdate(birthdate)
                                .email(email)
                                .photoUrl(photoUrl)
                                .category("Friend")
                                .build();
                        birthdayService.addBirthday(newBday, user);
                        importedCount++;
                    }
                }
            }
        }
        return importedCount;
    }

    public int exportBirthdaysToCalendar(User user) throws Exception {
        Credential credential = getCredential(user);
        com.google.api.services.calendar.Calendar calendarService = new com.google.api.services.calendar.Calendar.Builder(
                new NetHttpTransport(), GsonFactory.getDefaultInstance(), credential)
                .setApplicationName("Time2Wish")
                .build();
        
        java.util.List<Birthday> birthdays = birthdayService.getActiveBirthdays(user);
        int exportedCount = 0;

        for (Birthday b : birthdays) {
            com.google.api.services.calendar.model.Event event = new com.google.api.services.calendar.model.Event()
                .setSummary("🎂 Anniversaire de " + b.getName())
                .setDescription("Généré par Time2Wish. " + (b.getNotes() != null ? b.getNotes() : ""));

            java.time.LocalDate nextBday = b.getBirthdate().withYear(java.time.LocalDate.now().getYear());
            if (nextBday.isBefore(java.time.LocalDate.now())) {
                nextBday = nextBday.plusYears(1);
            }

            com.google.api.services.calendar.model.EventDateTime start = new com.google.api.services.calendar.model.EventDateTime()
                .setDate(new com.google.api.client.util.DateTime(nextBday.toString()));
            com.google.api.services.calendar.model.EventDateTime end = new com.google.api.services.calendar.model.EventDateTime()
                .setDate(new com.google.api.client.util.DateTime(nextBday.plusDays(1).toString()));
            
            event.setStart(start);
            event.setEnd(end);
            
            event.setRecurrence(Arrays.asList("RRULE:FREQ=YEARLY"));
            
            calendarService.events().insert("primary", event).execute();
            exportedCount++;
        }
        return exportedCount;
    }
}
