package app.time2wish.controller;

import app.time2wish.dto.AdminPasswordUpdateRequest;
import app.time2wish.dto.AdminUserDto;
import app.time2wish.dto.StatsResponse;
import app.time2wish.service.AdminService;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import app.time2wish.security.WebSecurityConfig;
import app.time2wish.security.JwtUtils;
import app.time2wish.security.UserDetailsServiceImpl;
import org.springframework.http.MediaType;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import org.springframework.test.web.servlet.MockMvc;

import java.util.List;
import java.util.Collections;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.Mockito.doNothing;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(AdminController.class)
@Import(WebSecurityConfig.class)
public class AdminControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private AdminService adminService;

    @MockitoBean
    private JwtUtils jwtUtils;

    @MockitoBean
    private UserDetailsServiceImpl userDetailsService;

    @MockitoBean
    private app.time2wish.service.SettingService settingService;

    private final ObjectMapper objectMapper = new ObjectMapper();

    // --- GET /api/admin/users ---

    @Test
    public void testGetUsersAdminAccess() throws Exception {
        when(adminService.getAllUsers()).thenReturn(List.of());
        mockMvc.perform(get("/api/admin/users").with(user("admin").roles("ADMIN")))
               .andExpect(status().isOk());
    }

    @Test
    public void testGetUsersUserAccess() throws Exception {
        mockMvc.perform(get("/api/admin/users").with(user("user").roles("USER")))
               .andExpect(status().isForbidden());
    }

    @Test
    public void testGetUsersAnonymousAccess() throws Exception {
        mockMvc.perform(get("/api/admin/users"))
               .andExpect(status().isUnauthorized());
    }

    // --- DELETE /api/admin/users/{id} ---

    @Test
    public void testDeleteUserAdminAccess() throws Exception {
        doNothing().when(adminService).deleteUser(anyLong());
        mockMvc.perform(delete("/api/admin/users/1").with(user("admin").roles("ADMIN")).with(csrf()))
               .andExpect(status().isNoContent());
    }

    @Test
    public void testDeleteUserUserAccess() throws Exception {
        mockMvc.perform(delete("/api/admin/users/1").with(user("user").roles("USER")).with(csrf()))
               .andExpect(status().isForbidden());
    }

    @Test
    public void testDeleteUserAnonymousAccess() throws Exception {
        mockMvc.perform(delete("/api/admin/users/1"))
               .andExpect(status().isUnauthorized());
    }

    @Test
    public void testDeleteUserNotFound() throws Exception {
        org.mockito.Mockito.doThrow(new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.NOT_FOUND))
                .when(adminService).deleteUser(anyLong());
        mockMvc.perform(delete("/api/admin/users/999").with(user("admin").roles("ADMIN")).with(csrf()))
               .andExpect(status().isNotFound());
    }

    // --- PUT /api/admin/users/{id}/password ---

    @Test
    public void testUpdatePasswordAdminAccess() throws Exception {
        AdminPasswordUpdateRequest request = new AdminPasswordUpdateRequest("newPass");
        doNothing().when(adminService).updateUserPassword(anyLong(), any());
        
        mockMvc.perform(put("/api/admin/users/1/password")
                .with(user("admin").roles("ADMIN")).with(csrf())
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
               .andExpect(status().isNoContent());
    }

    @Test
    public void testUpdatePasswordNotFound() throws Exception {
        AdminPasswordUpdateRequest request = new AdminPasswordUpdateRequest("newPass");
        org.mockito.Mockito.doThrow(new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.NOT_FOUND))
                .when(adminService).updateUserPassword(anyLong(), any());
        
        mockMvc.perform(put("/api/admin/users/999/password")
                .with(user("admin").roles("ADMIN")).with(csrf())
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
               .andExpect(status().isNotFound());
    }

    @Test
    public void testUpdatePasswordUserAccess() throws Exception {
        AdminPasswordUpdateRequest request = new AdminPasswordUpdateRequest("newPass");
        mockMvc.perform(put("/api/admin/users/1/password")
                .with(user("user").roles("USER")).with(csrf())
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
               .andExpect(status().isForbidden());
    }

    @Test
    public void testUpdatePasswordAnonymousAccess() throws Exception {
        AdminPasswordUpdateRequest request = new AdminPasswordUpdateRequest("newPass");
        mockMvc.perform(put("/api/admin/users/1/password")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
               .andExpect(status().isUnauthorized());
    }

    // --- GET /api/admin/stats ---

    @Test
    public void testGetStatsAdminAccess() throws Exception {
        StatsResponse statsResponse = new StatsResponse(10, 50, Collections.emptyMap(), Collections.emptyMap(), Collections.emptyList(), 0.0, Collections.emptyMap());
        when(adminService.getStats()).thenReturn(statsResponse);
        mockMvc.perform(get("/api/admin/stats").with(user("admin").roles("ADMIN")))
               .andExpect(status().isOk());
    }

    @Test
    public void testGetStatsUserAccess() throws Exception {
        mockMvc.perform(get("/api/admin/stats").with(user("user").roles("USER")))
               .andExpect(status().isForbidden());
    }

    @Test
    public void testGetStatsAnonymousAccess() throws Exception {
        mockMvc.perform(get("/api/admin/stats"))
               .andExpect(status().isUnauthorized());
    }
}
