package com.nalamai.backend.models;

import jakarta.persistence.*;
import java.time.LocalDateTime;

/**
 * Follow-up tracking for preventive care adherence.
 * Monitors patient compliance and engagement.
 */
@Entity
@Table(name = "follow_ups")
public class FollowUp {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "patient_id", nullable = false)
    private User patient;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "prevention_plan_id")
    private PreventionPlan preventionPlan;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "appointment_id")
    private Appointment appointment;

    @Column(nullable = false)
    private String followUpType; // MEDICATION, APPOINTMENT, SCREENING, LIFESTYLE, FEEDBACK

    @Column(nullable = false)
    private String status; // PENDING, SENT, ACKNOWLEDGED, COMPLETED, OVERDUE, SKIPPED

    private LocalDateTime scheduledDate;
    private LocalDateTime sentDate;
    private LocalDateTime respondedDate;

    @Column(columnDefinition = "TEXT")
    private String message;

    @Column(columnDefinition = "TEXT")
    private String patientResponse;

    // Communication Channel
    private String channel; // EMAIL, SMS, IN_APP, CALL

    private Integer attemptCount;
    private Integer maxAttempts;

    // Adherence Tracking
    private Boolean taskCompleted;
    private Integer adherenceScore; // 0-100

    @Column(columnDefinition = "TEXT")
    private String feedback; // Patient feedback JSON

    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt = LocalDateTime.now();

    private LocalDateTime updatedAt;

    // Constructors
    public FollowUp() {}

    // Getters and Setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public User getPatient() { return patient; }
    public void setPatient(User patient) { this.patient = patient; }

    public PreventionPlan getPreventionPlan() { return preventionPlan; }
    public void setPreventionPlan(PreventionPlan preventionPlan) { this.preventionPlan = preventionPlan; }

    public Appointment getAppointment() { return appointment; }
    public void setAppointment(Appointment appointment) { this.appointment = appointment; }

    public String getFollowUpType() { return followUpType; }
    public void setFollowUpType(String followUpType) { this.followUpType = followUpType; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public LocalDateTime getScheduledDate() { return scheduledDate; }
    public void setScheduledDate(LocalDateTime scheduledDate) { this.scheduledDate = scheduledDate; }

    public LocalDateTime getSentDate() { return sentDate; }
    public void setSentDate(LocalDateTime sentDate) { this.sentDate = sentDate; }

    public LocalDateTime getRespondedDate() { return respondedDate; }
    public void setRespondedDate(LocalDateTime respondedDate) { this.respondedDate = respondedDate; }

    public String getMessage() { return message; }
    public void setMessage(String message) { this.message = message; }

    public String getPatientResponse() { return patientResponse; }
    public void setPatientResponse(String patientResponse) { this.patientResponse = patientResponse; }

    public String getChannel() { return channel; }
    public void setChannel(String channel) { this.channel = channel; }

    public Integer getAttemptCount() { return attemptCount; }
    public void setAttemptCount(Integer attemptCount) { this.attemptCount = attemptCount; }

    public Integer getMaxAttempts() { return maxAttempts; }
    public void setMaxAttempts(Integer maxAttempts) { this.maxAttempts = maxAttempts; }

    public Boolean getTaskCompleted() { return taskCompleted; }
    public void setTaskCompleted(Boolean taskCompleted) { this.taskCompleted = taskCompleted; }

    public Integer getAdherenceScore() { return adherenceScore; }
    public void setAdherenceScore(Integer adherenceScore) { this.adherenceScore = adherenceScore; }

    public String getFeedback() { return feedback; }
    public void setFeedback(String feedback) { this.feedback = feedback; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }

    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(LocalDateTime updatedAt) { this.updatedAt = updatedAt; }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}
