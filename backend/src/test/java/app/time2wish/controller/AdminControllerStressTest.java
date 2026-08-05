package app.time2wish.controller;

import app.time2wish.dto.AdminPasswordUpdateRequest;
import app.time2wish.model.Role;
import app.time2wish.model.User;
import app.time2wish.repository.UserRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.web.servlet.MockMvc;

import java.util.ArrayList;
import java.util.List;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.junit.jupiter.api.Assertions.assertEquals;

@SpringBootTest
@AutoConfigureMockMvc
public class AdminControllerStressTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private UserRepository userRepository;

    private final ObjectMapper objectMapper = new ObjectMapper();

    @BeforeEach
    public void setup() {
        userRepository.deleteAll();
    }

    @Test
    @WithMockUser(roles = "ADMIN")
    public void testStressGetAllUsers() throws Exception {
        // Insert 1000 users to test performance and memory issues
        List<User> users = new ArrayList<>();
        for (int i = 0; i < 1000; i++) {
            User u = User.builder()
                .email("user" + i + "@example.com")
                .password("password")
                .fullName("User " + i)
                .role(Role.ROLE_USER)
                .build();
            users.add(u);
        }
        userRepository.saveAll(users);

        long start = System.currentTimeMillis();
        mockMvc.perform(get("/api/admin/users"))
               .andExpect(status().isOk());
        long duration = System.currentTimeMillis() - start;
        System.out.println("Time to fetch 1000 users: " + duration + " ms");
        
        // Let's assert it doesn't take an excessively long time, but also just verifying it works without OOM.
    }

    @Test
    @WithMockUser(roles = "ADMIN")
    public void testUpdatePasswordWithEmptyString() throws Exception {
        User u = User.builder()
                .email("test@example.com")
                .password("oldpassword")
                .fullName("Test User")
                .role(Role.ROLE_USER)
                .build();
        userRepository.save(u);

        AdminPasswordUpdateRequest request = new AdminPasswordUpdateRequest("");

        mockMvc.perform(put("/api/admin/users/" + u.getId() + "/password")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
               .andExpect(status().isBadRequest()); // Expecting 400 Bad Request due to validation, but it will probably be 204 No Content
    }

    @Test
    @WithMockUser(roles = "ADMIN")
    public void testDeleteNonExistentUser() throws Exception {
        mockMvc.perform(delete("/api/admin/users/999999"))
               .andExpect(status().isNotFound()); // Expecting 404, but it will probably be 500 Internal Server Error
    }
}
