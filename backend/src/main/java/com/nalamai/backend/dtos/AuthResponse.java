package com.nalamai.backend.dtos;

import com.nalamai.backend.models.DoctorProfile;
import com.nalamai.backend.models.UserProfile;

public class AuthResponse {
    private Long id;
    private String email;
    private String name;
    private String role;
    private String token;
    private UserProfile userProfile;
    private DoctorProfile doctorProfile;

    // Constructors
    public AuthResponse() {
    }

    public AuthResponse(Long id, String email, String name, String role, String token) {
        this.id = id;
        this.email = email;
        this.name = name;
        this.role = role;
        this.token = token;
    }

    public AuthResponse(Long id, String email, String name, String role, String token, UserProfile userProfile, DoctorProfile doctorProfile) {
        this.id = id;
        this.email = email;
        this.name = name;
        this.role = role;
        this.token = token;
        this.userProfile = userProfile;
        this.doctorProfile = doctorProfile;
    }

    // Getters and Setters
    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getRole() {
        return role;
    }

    public void setRole(String role) {
        this.role = role;
    }

    public String getToken() {
        return token;
    }

    public void setToken(String token) {
        this.token = token;
    }

    public UserProfile getUserProfile() {
        return userProfile;
    }

    public void setUserProfile(UserProfile userProfile) {
        this.userProfile = userProfile;
    }

    public DoctorProfile getDoctorProfile() {
        return doctorProfile;
    }

    public void setDoctorProfile(DoctorProfile doctorProfile) {
        this.doctorProfile = doctorProfile;
    }
}
