package com.nalamai.backend.models;

import jakarta.persistence.*;
import java.time.LocalDateTime;

/**
 * Health Risk Assessment (HRA) model for preventive healthcare.
 * Stores patient health questionnaire data and risk scores.
 */
@Entity
@Table(name = "health_risk_assessments")
public class HealthRiskAssessment {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "patient_id", nullable = false)
    private User patient;

    @Column(nullable = false)
    private String status; // PENDING, SUBMITTED, VALIDATED, FLAGGED

    @Column(nullable = false)
    private LocalDateTime assessmentDate;

    private LocalDateTime validatedDate;

    // Risk Scores (0-100)
    private Integer cardiovascularRisk;
    private Integer diabetesRisk;
    private Integer cancerRisk;
    private Integer overallRisk;

    // Lifestyle Factors
    private Boolean isSmoker;
    private Boolean consumesAlcohol;
    private String exerciseFrequency; // NONE, RARE, MODERATE, REGULAR
    private String dietQuality; // POOR, FAIR, GOOD, EXCELLENT

    // Health History
    @Column(columnDefinition = "TEXT")
    private String familyHistory; // JSON array of conditions
    
    @Column(columnDefinition = "TEXT")
    private String personalHistory; // JSON array of conditions

    @Column(columnDefinition = "TEXT")
    private String currentMedications; // JSON array

    @Column(columnDefinition = "TEXT")
    private String allergies; // JSON array

    // Biometrics
    private Double height; // cm
    private Double weight; // kg
    private Double bmi;
    private Integer systolicBP;
    private Integer diastolicBP;
    private Integer fastingGlucose;
    private Integer cholesterol;

    // AI-Generated Insights
    @Column(columnDefinition = "TEXT")
    private String aiInsights; // JSON with AI recommendations

    @Column(columnDefinition = "TEXT")
    private String flags; // JSON array of flagged issues

    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt = LocalDateTime.now();

    private LocalDateTime updatedAt;

    // Constructors
    public HealthRiskAssessment() {}

    // Getters and Setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public User getPatient() { return patient; }
    public void setPatient(User patient) { this.patient = patient; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public LocalDateTime getAssessmentDate() { return assessmentDate; }
    public void setAssessmentDate(LocalDateTime assessmentDate) { this.assessmentDate = assessmentDate; }

    public LocalDateTime getValidatedDate() { return validatedDate; }
    public void setValidatedDate(LocalDateTime validatedDate) { this.validatedDate = validatedDate; }

    public Integer getCardiovascularRisk() { return cardiovascularRisk; }
    public void setCardiovascularRisk(Integer cardiovascularRisk) { this.cardiovascularRisk = cardiovascularRisk; }

    public Integer getDiabetesRisk() { return diabetesRisk; }
    public void setDiabetesRisk(Integer diabetesRisk) { this.diabetesRisk = diabetesRisk; }

    public Integer getCancerRisk() { return cancerRisk; }
    public void setCancerRisk(Integer cancerRisk) { this.cancerRisk = cancerRisk; }

    public Integer getOverallRisk() { return overallRisk; }
    public void setOverallRisk(Integer overallRisk) { this.overallRisk = overallRisk; }

    public Boolean getIsSmoker() { return isSmoker; }
    public void setIsSmoker(Boolean isSmoker) { this.isSmoker = isSmoker; }

    public Boolean getConsumesAlcohol() { return consumesAlcohol; }
    public void setConsumesAlcohol(Boolean consumesAlcohol) { this.consumesAlcohol = consumesAlcohol; }

    public String getExerciseFrequency() { return exerciseFrequency; }
    public void setExerciseFrequency(String exerciseFrequency) { this.exerciseFrequency = exerciseFrequency; }

    public String getDietQuality() { return dietQuality; }
    public void setDietQuality(String dietQuality) { this.dietQuality = dietQuality; }

    public String getFamilyHistory() { return familyHistory; }
    public void setFamilyHistory(String familyHistory) { this.familyHistory = familyHistory; }

    public String getPersonalHistory() { return personalHistory; }
    public void setPersonalHistory(String personalHistory) { this.personalHistory = personalHistory; }

    public String getCurrentMedications() { return currentMedications; }
    public void setCurrentMedications(String currentMedications) { this.currentMedications = currentMedications; }

    public String getAllergies() { return allergies; }
    public void setAllergies(String allergies) { this.allergies = allergies; }

    public Double getHeight() { return height; }
    public void setHeight(Double height) { this.height = height; }

    public Double getWeight() { return weight; }
    public void setWeight(Double weight) { this.weight = weight; }

    public Double getBmi() { return bmi; }
    public void setBmi(Double bmi) { this.bmi = bmi; }

    public Integer getSystolicBP() { return systolicBP; }
    public void setSystolicBP(Integer systolicBP) { this.systolicBP = systolicBP; }

    public Integer getDiastolicBP() { return diastolicBP; }
    public void setDiastolicBP(Integer diastolicBP) { this.diastolicBP = diastolicBP; }

    public Integer getFastingGlucose() { return fastingGlucose; }
    public void setFastingGlucose(Integer fastingGlucose) { this.fastingGlucose = fastingGlucose; }

    public Integer getCholesterol() { return cholesterol; }
    public void setCholesterol(Integer cholesterol) { this.cholesterol = cholesterol; }

    public String getAiInsights() { return aiInsights; }
    public void setAiInsights(String aiInsights) { this.aiInsights = aiInsights; }

    public String getFlags() { return flags; }
    public void setFlags(String flags) { this.flags = flags; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }

    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(LocalDateTime updatedAt) { this.updatedAt = updatedAt; }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}
