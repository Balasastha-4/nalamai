package com.nalamai.backend.models;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "vitals", indexes = {
        @Index(name = "idx_user_id", columnList = "user_id"),
        @Index(name = "idx_type", columnList = "type")
})
public class Vital {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(nullable = false, length = 50)
    private String type; // HeartRate, BP, SpO2, Temperature, Weight, BMI

    @Column(nullable = false)
    private Double value;

    @Column(length = 20)
    private String unit;

    @Column(nullable = false)
    private Boolean isAlert = false;

    @Column(nullable = false)
    private LocalDateTime timestamp;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        if (timestamp == null) {
            timestamp = LocalDateTime.now();
        }
    }

    // Constructors
    public Vital() {
    }

    public Vital(User user, String type, Double value, String unit) {
        this.user = user;
        this.type = type;
        this.value = value;
        this.unit = unit;
        this.timestamp = LocalDateTime.now();
    }

    public Vital(User user, String type, Double value, String unit, Boolean isAlert, LocalDateTime timestamp) {
        this.user = user;
        this.type = type;
        this.value = value;
        this.unit = unit;
        this.isAlert = isAlert;
        this.timestamp = timestamp;
    }

    // Getters and Setters
    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public User getUser() {
        return user;
    }

    public void setUser(User user) {
        this.user = user;
    }

    public String getType() {
        return type;
    }

    public void setType(String type) {
        this.type = type;
    }

    public Double getValue() {
        return value;
    }

    public void setValue(Double value) {
        this.value = value;
    }

    public String getUnit() {
        return unit;
    }

    public void setUnit(String unit) {
        this.unit = unit;
    }

    public Boolean getIsAlert() {
        return isAlert;
    }

    public void setIsAlert(Boolean isAlert) {
        this.isAlert = isAlert;
    }

    public LocalDateTime getTimestamp() {
        return timestamp;
    }

    public void setTimestamp(LocalDateTime timestamp) {
        this.timestamp = timestamp;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    @Override
    public String toString() {
        return "Vital{" +
                "id=" + id +
                ", type='" + type + '\'' +
                ", value=" + value +
                ", unit='" + unit + '\'' +
                ", isAlert=" + isAlert +
                ", timestamp=" + timestamp +
                ", createdAt=" + createdAt +
                '}';
    }
}
