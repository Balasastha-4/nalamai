package com.nalamai.backend.models;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "video_calls")
public class VideoCall {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "doctor_id", nullable = false)
    private User doctor;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "patient_id", nullable = false)
    private User patient;

    @Column(nullable = false, unique = true, length = 100)
    private String roomId;

    @Column(nullable = false, length = 50)
    private String status; // PENDING, ACTIVE, COMPLETED

    @Column(name = "scheduled_time")
    private LocalDateTime scheduledTime;

    @Column(name = "duration")
    private Integer duration; // in minutes

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }

    // Constructors
    public VideoCall() {
    }

    public VideoCall(User doctor, User patient, String roomId) {
        this.doctor = doctor;
        this.patient = patient;
        this.roomId = roomId;
        this.status = "PENDING";
    }

    public VideoCall(User doctor, User patient, String roomId, String status, LocalDateTime scheduledTime) {
        this.doctor = doctor;
        this.patient = patient;
        this.roomId = roomId;
        this.status = status;
        this.scheduledTime = scheduledTime;
    }

    // Getters and Setters
    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public User getDoctor() {
        return doctor;
    }

    public void setDoctor(User doctor) {
        this.doctor = doctor;
    }

    public User getPatient() {
        return patient;
    }

    public void setPatient(User patient) {
        this.patient = patient;
    }

    public String getRoomId() {
        return roomId;
    }

    public void setRoomId(String roomId) {
        this.roomId = roomId;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public LocalDateTime getScheduledTime() {
        return scheduledTime;
    }

    public void setScheduledTime(LocalDateTime scheduledTime) {
        this.scheduledTime = scheduledTime;
    }

    public Integer getDuration() {
        return duration;
    }

    public void setDuration(Integer duration) {
        this.duration = duration;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    @Override
    public String toString() {
        return "VideoCall{" +
                "id=" + id +
                ", roomId='" + roomId + '\'' +
                ", status='" + status + '\'' +
                ", scheduledTime=" + scheduledTime +
                ", duration=" + duration +
                ", createdAt=" + createdAt +
                '}';
    }
}
