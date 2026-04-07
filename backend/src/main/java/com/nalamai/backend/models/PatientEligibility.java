package com.nalamai.backend.models;

import jakarta.persistence.*;
import java.time.LocalDateTime;

/**
 * Patient Eligibility model for preventive care programs.
 * Tracks patient eligibility for various wellness programs.
 */
@Entity
@Table(name = "patient_eligibility")
public class PatientEligibility {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "patient_id", nullable = false)
    private User patient;

    @Column(nullable = false)
    private String programType; // ANNUAL_WELLNESS, PREVENTIVE_SCREENING, CHRONIC_CARE_MANAGEMENT

    @Column(nullable = false)
    private Boolean isEligible;

    @Column(nullable = false)
    private String eligibilityStatus; // ELIGIBLE, NOT_ELIGIBLE, PENDING_REVIEW, RECENTLY_COMPLETED

    private LocalDateTime lastCompletedDate;
    private LocalDateTime nextEligibleDate;
    private LocalDateTime calculatedDate;

    // Eligibility Criteria
    private Integer ageYears;
    private String insuranceType;
    private Boolean hasRequiredCoverage;
    
    @Column(columnDefinition = "TEXT")
    private String eligibilityCriteria; // JSON with criteria met/not met

    @Column(columnDefinition = "TEXT")
    private String notes;

    // AI-determined risk priority
    private Integer riskScore;
    private String riskCategory; // HIGH, MEDIUM, LOW
    private Boolean priorityOutreach;

    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt = LocalDateTime.now();

    private LocalDateTime updatedAt;

    // Constructors
    public PatientEligibility() {}

    // Getters and Setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public User getPatient() { return patient; }
    public void setPatient(User patient) { this.patient = patient; }

    public String getProgramType() { return programType; }
    public void setProgramType(String programType) { this.programType = programType; }

    public Boolean getIsEligible() { return isEligible; }
    public void setIsEligible(Boolean isEligible) { this.isEligible = isEligible; }

    public String getEligibilityStatus() { return eligibilityStatus; }
    public void setEligibilityStatus(String eligibilityStatus) { this.eligibilityStatus = eligibilityStatus; }

    public LocalDateTime getLastCompletedDate() { return lastCompletedDate; }
    public void setLastCompletedDate(LocalDateTime lastCompletedDate) { this.lastCompletedDate = lastCompletedDate; }

    public LocalDateTime getNextEligibleDate() { return nextEligibleDate; }
    public void setNextEligibleDate(LocalDateTime nextEligibleDate) { this.nextEligibleDate = nextEligibleDate; }

    public LocalDateTime getCalculatedDate() { return calculatedDate; }
    public void setCalculatedDate(LocalDateTime calculatedDate) { this.calculatedDate = calculatedDate; }

    public Integer getAgeYears() { return ageYears; }
    public void setAgeYears(Integer ageYears) { this.ageYears = ageYears; }

    public String getInsuranceType() { return insuranceType; }
    public void setInsuranceType(String insuranceType) { this.insuranceType = insuranceType; }

    public Boolean getHasRequiredCoverage() { return hasRequiredCoverage; }
    public void setHasRequiredCoverage(Boolean hasRequiredCoverage) { this.hasRequiredCoverage = hasRequiredCoverage; }

    public String getEligibilityCriteria() { return eligibilityCriteria; }
    public void setEligibilityCriteria(String eligibilityCriteria) { this.eligibilityCriteria = eligibilityCriteria; }

    public String getNotes() { return notes; }
    public void setNotes(String notes) { this.notes = notes; }

    public Integer getRiskScore() { return riskScore; }
    public void setRiskScore(Integer riskScore) { this.riskScore = riskScore; }

    public String getRiskCategory() { return riskCategory; }
    public void setRiskCategory(String riskCategory) { this.riskCategory = riskCategory; }

    public Boolean getPriorityOutreach() { return priorityOutreach; }
    public void setPriorityOutreach(Boolean priorityOutreach) { this.priorityOutreach = priorityOutreach; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }

    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(LocalDateTime updatedAt) { this.updatedAt = updatedAt; }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}
