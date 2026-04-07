package com.nalamai.backend.dtos;

public class UserUpdateRequest {
    private String name;
    private String phone;
    private String address;
    private String profilePictureUrl;
    private String dateOfBirth;

    // Constructors
    public UserUpdateRequest() {
    }

    public UserUpdateRequest(String name, String phone, String address, String profilePictureUrl, String dateOfBirth) {
        this.name = name;
        this.phone = phone;
        this.address = address;
        this.profilePictureUrl = profilePictureUrl;
        this.dateOfBirth = dateOfBirth;
    }

    // Getters and Setters
    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getPhone() {
        return phone;
    }

    public void setPhone(String phone) {
        this.phone = phone;
    }

    public String getAddress() {
        return address;
    }

    public void setAddress(String address) {
        this.address = address;
    }

    public String getProfilePictureUrl() {
        return profilePictureUrl;
    }

    public void setProfilePictureUrl(String profilePictureUrl) {
        this.profilePictureUrl = profilePictureUrl;
    }

    public String getDateOfBirth() {
        return dateOfBirth;
    }

    public void setDateOfBirth(String dateOfBirth) {
        this.dateOfBirth = dateOfBirth;
    }
}
