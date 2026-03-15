package com.nalamai.backend.models;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "medical_resources")
public class MedicalResource {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String name;

    @Column(nullable = false)
    private String type; // e.g., "X-RAY", "DENTAL_CHAIR", "CONSULTATION_ROOM"

    @Column(nullable = false)
    private String status; // "AVAILABLE", "IN_USE", "MAINTENANCE"

    private String location;

    @Column(updatable = false)
    private LocalDateTime createdAt = LocalDateTime.now();

    public MedicalResource() {}

    public MedicalResource(String name, String type, String status, String location) {
        this.name = name;
        this.type = type;
        this.status = status;
        this.location = location;
    }

    // Getters and Setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public String getType() { return type; }
    public void setType(String type) { this.type = type; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public String getLocation() { return location; }
    public void setLocation(String location) { this.location = location; }

    public LocalDateTime getCreatedAt() { return createdAt; }
}
