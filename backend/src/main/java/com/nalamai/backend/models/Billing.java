package com.nalamai.backend.models;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "billings")
public class Billing {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private Long patientId;

    @Column(nullable = false)
    private Double totalAmount;

    @Column(nullable = false)
    private String status; // "PENDING", "PAID", "INSURANCE_CLAIMED"

    @Column(columnDefinition = "TEXT")
    private String itemsJson; // Stores medicines/services list as JSON string

    @Column(updatable = false)
    private LocalDateTime createdAt = LocalDateTime.now();

    public Billing() {}

    public Billing(Long patientId, Double totalAmount, String status, String itemsJson) {
        this.patientId = patientId;
        this.totalAmount = totalAmount;
        this.status = status;
        this.itemsJson = itemsJson;
    }

    // Getters and Setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Long getPatientId() { return patientId; }
    public void setPatientId(Long patientId) { this.patientId = patientId; }

    public Double getTotalAmount() { return totalAmount; }
    public void setTotalAmount(Double totalAmount) { this.totalAmount = totalAmount; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public String getItemsJson() { return itemsJson; }
    public void setItemsJson(String itemsJson) { this.itemsJson = itemsJson; }

    public LocalDateTime getCreatedAt() { return createdAt; }
}
