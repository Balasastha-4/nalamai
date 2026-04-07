package com.nalamai.backend.models;

import jakarta.persistence.*;
import java.time.LocalDateTime;

/**
 * Prevention Plan model for personalized preventive care.
 * Contains AI-generated and provider-approved care plans.
 */
@Entity
@Table(name = "prevention_plans")
public class PreventionPlan {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "patient_id", nullable = false)
    private User patient;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "doctor_id")
    private User doctor;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "hra_id")
    private HealthRiskAssessment hra;

    @Column(nullable = false)
    private String status; // DRAFT, ACTIVE, COMPLETED, ARCHIVED

    @Column(nullable = false)
    private String planType; // ANNUAL_WELLNESS, CHRONIC_CARE, PREVENTIVE_SCREENING

    private LocalDateTime startDate;
    private LocalDateTime endDate;

    // Goals and Interventions (JSON)
    @Column(columnDefinition = "TEXT")
    private String healthGoals; // JSON array of goals

    @Column(columnDefinition = "TEXT")
    private String preventiveMeasures; // JSON array of measures

    @Column(columnDefinition = "TEXT")
    private String recommendedScreenings; // JSON array with dates

    @Column(columnDefinition = "TEXT")
    private String lifestyleRecommendations; // JSON array

    @Column(columnDefinition = "TEXT")
    private String medicationPlan; // JSON array

    // Referrals
    @Column(columnDefinition = "TEXT")
    private String specialistReferrals; // JSON array

    // Progress Tracking
    private Integer completionPercentage;
    
    @Column(columnDefinition = "TEXT")
    private String progressNotes; // JSON array of progress entries

    // AI-Generated Content
    @Column(columnDefinition = "TEXT")
    private String aiRecommendations;
    
    private Boolean aiGenerated;
    private Boolean providerApproved;
    private LocalDateTime approvedDate;

    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt = LocalDateTime.now();

    private LocalDateTime updatedAt;

    // Constructors
    public PreventionPlan() {}

    // Getters and Setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public User getPatient() { return patient; }
    public void setPatient(User patient) { this.patient = patient; }

    public User getDoctor() { return doctor; }
    public void setDoctor(User doctor) { this.doctor = doctor; }

    public HealthRiskAssessment getHra() { return hra; }
    public void setHra(HealthRiskAssessment hra) { this.hra = hra; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public String getPlanType() { return planType; }
    public void setPlanType(String planType) { this.planType = planType; }

    public LocalDateTime getStartDate() { return startDate; }
    public void setStartDate(LocalDateTime startDate) { this.startDate = startDate; }

    public LocalDateTime getEndDate() { return endDate; }
    public void setEndDate(LocalDateTime endDate) { this.endDate = endDate; }

    public String getHealthGoals() { return healthGoals; }
    public void setHealthGoals(String healthGoals) { this.healthGoals = healthGoals; }

    public String getPreventiveMeasures() { return preventiveMeasures; }
    public void setPreventiveMeasures(String preventiveMeasures) { this.preventiveMeasures = preventiveMeasures; }

    public String getRecommendedScreenings() { return recommendedScreenings; }
    public void setRecommendedScreenings(String recommendedScreenings) { this.recommendedScreenings = recommendedScreenings; }

    public String getLifestyleRecommendations() { return lifestyleRecommendations; }
    public void setLifestyleRecommendations(String lifestyleRecommendations) { this.lifestyleRecommendations = lifestyleRecommendations; }

    public String getMedicationPlan() { return medicationPlan; }
    public void setMedicationPlan(String medicationPlan) { this.medicationPlan = medicationPlan; }

    public String getSpecialistReferrals() { return specialistReferrals; }
    public void setSpecialistReferrals(String specialistReferrals) { this.specialistReferrals = specialistReferrals; }

    public Integer getCompletionPercentage() { return completionPercentage; }
    public void setCompletionPercentage(Integer completionPercentage) { this.completionPercentage = completionPercentage; }

    public String getProgressNotes() { return progressNotes; }
    public void setProgressNotes(String progressNotes) { this.progressNotes = progressNotes; }

    public String getAiRecommendations() { return aiRecommendations; }
    public void setAiRecommendations(String aiRecommendations) { this.aiRecommendations = aiRecommendations; }

    public Boolean getAiGenerated() { return aiGenerated; }
    public void setAiGenerated(Boolean aiGenerated) { this.aiGenerated = aiGenerated; }

    public Boolean getProviderApproved() { return providerApproved; }
    public void setProviderApproved(Boolean providerApproved) { this.providerApproved = providerApproved; }

    public LocalDateTime getApprovedDate() { return approvedDate; }
    public void setApprovedDate(LocalDateTime approvedDate) { this.approvedDate = approvedDate; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }

    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(LocalDateTime updatedAt) { this.updatedAt = updatedAt; }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}
