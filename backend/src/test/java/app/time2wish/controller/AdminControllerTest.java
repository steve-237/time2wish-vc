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
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.web.servlet.MockMvc;

import java.util.List;

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

    @Autowired
    private ObjectMapper objectMapper;

    // --- GET /api/admin/users ---

    @Test
    @WithMockUser(roles = "ADMIN")
    public void testGetUsersAdminAccess() throws Exception {
        when(adminService.getAllUsers()).thenReturn(List.of());
        mockMvc.perform(get("/api/admin/users"))
               .andExpect(status().isOk());
    }

    @Test
    @WithMockUser(roles = "USER")
    public void testGetUsersUserAccess() throws Exception {
        mockMvc.perform(get("/api/admin/users"))
               .andExpect(status().isForbidden());
    }

    @Test
    public void testGetUsersAnonymousAccess() throws Exception {
        mockMvc.perform(get("/api/admin/users"))
               .andExpect(status().isUnauthorized());
    }

    // --- DELETE /api/admin/users/{id} ---

    @Test
    @WithMockUser(roles = "ADMIN")
    public void testDeleteUserAdminAccess() throws Exception {
        doNothing().when(adminService).deleteUser(anyLong());
        mockMvc.perform(delete("/api/admin/users/1"))
               .andExpect(status().isNoContent());
    }

    @Test
    @WithMockUser(roles = "USER")
    public void testDeleteUserUserAccess() throws Exception {
        mockMvc.perform(delete("/api/admin/users/1"))
               .andExpect(status().isForbidden());
    }

    @Test
    public void testDeleteUserAnonymousAccess() throws Exception {
        mockMvc.perform(delete("/api/admin/users/1"))
               .andExpect(status().isUnauthorized());
    }

    @Test
    @WithMockUser(roles = "ADMIN")
    public void testDeleteUserNotFound() throws Exception {
        org.mockito.Mockito.doThrow(new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.NOT_FOUND))
                .when(adminService).deleteUser(anyLong());
        mockMvc.perform(delete("/api/admin/users/999"))
               .andExpect(status().isNotFound());
    }

    // --- PUT /api/admin/users/{id}/password ---

    @Test
    @WithMockUser(roles = "ADMIN")
    public void testUpdatePasswordAdminAccess() throws Exception {
        AdminPasswordUpdateRequest request = new AdminPasswordUpdateRequest("newPass");
        doNothing().when(adminService).updateUserPassword(anyLong(), any());
        
        mockMvc.perform(put("/api/admin/users/1/password")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
               .andExpect(status().isNoContent());
    }

    @Test
    @WithMockUser(roles = "ADMIN")
    public void testUpdatePasswordNotFound() throws Exception {
        AdminPasswordUpdateRequest request = new AdminPasswordUpdateRequest("newPass");
        org.mockito.Mockito.doThrow(new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.NOT_FOUND))
                .when(adminService).updateUserPassword(anyLong(), any());
        
        mockMvc.perform(put("/api/admin/users/999/password")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
               .andExpect(status().isNotFound());
    }

    @Test
    @WithMockUser(roles = "USER")
    public void testUpdatePasswordUserAccess() throws Exception {
        AdminPasswordUpdateRequest request = new AdminPasswordUpdateRequest("newPass");
        mockMvc.perform(put("/api/admin/users/1/password")
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
    @WithMockUser(roles = "ADMIN")
    public void testGetStatsAdminAccess() throws Exception {
        StatsResponse statsResponse = new StatsResponse(10, 50, Collections.emptyMap(), Collections.emptyMap(), Collections.emptyList(), 0.0, Collections.emptyMap());
        when(adminService.getStats()).thenReturn(statsResponse);
        mockMvc.perform(get("/api/admin/stats"))
               .andExpect(status().isOk());
    }

    @Test
    @WithMockUser(roles = "USER")
    public void testGetStatsUserAccess() throws Exception {
        mockMvc.perform(get("/api/admin/stats"))
               .andExpect(status().isForbidden());
    }

    @Test
    public void testGetStatsAnonymousAccess() throws Exception {
        mockMvc.perform(get("/api/admin/stats"))
               .andExpect(status().isUnauthorized());
    }
}
