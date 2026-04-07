package com.nalamai.backend.models;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "connected_devices")
public class ConnectedDevice {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(nullable = false, length = 100)
    private String deviceName;

    @Column(nullable = false, length = 50)
    private String deviceType; // bpMonitor, glucoseMeter, pulseOximeter

    @Column(nullable = false)
    private Boolean isConnected = false;

    @Column(name = "battery_level")
    private Integer batteryLevel;

    @Column(name = "last_reading", length = 500)
    private String lastReading;

    @Column(name = "last_reading_time")
    private LocalDateTime lastReadingTime;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }

    // Constructors
    public ConnectedDevice() {
    }

    public ConnectedDevice(User user, String deviceName, String deviceType) {
        this.user = user;
        this.deviceName = deviceName;
        this.deviceType = deviceType;
    }

    public ConnectedDevice(User user, String deviceName, String deviceType, Boolean isConnected,
                           Integer batteryLevel, String lastReading, LocalDateTime lastReadingTime) {
        this.user = user;
        this.deviceName = deviceName;
        this.deviceType = deviceType;
        this.isConnected = isConnected;
        this.batteryLevel = batteryLevel;
        this.lastReading = lastReading;
        this.lastReadingTime = lastReadingTime;
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

    public String getDeviceName() {
        return deviceName;
    }

    public void setDeviceName(String deviceName) {
        this.deviceName = deviceName;
    }

    public String getDeviceType() {
        return deviceType;
    }

    public void setDeviceType(String deviceType) {
        this.deviceType = deviceType;
    }

    public Boolean getIsConnected() {
        return isConnected;
    }

    public void setIsConnected(Boolean isConnected) {
        this.isConnected = isConnected;
    }

    public Integer getBatteryLevel() {
        return batteryLevel;
    }

    public void setBatteryLevel(Integer batteryLevel) {
        this.batteryLevel = batteryLevel;
    }

    public String getLastReading() {
        return lastReading;
    }

    public void setLastReading(String lastReading) {
        this.lastReading = lastReading;
    }

    public LocalDateTime getLastReadingTime() {
        return lastReadingTime;
    }

    public void setLastReadingTime(LocalDateTime lastReadingTime) {
        this.lastReadingTime = lastReadingTime;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    @Override
    public String toString() {
        return "ConnectedDevice{" +
                "id=" + id +
                ", deviceName='" + deviceName + '\'' +
                ", deviceType='" + deviceType + '\'' +
                ", isConnected=" + isConnected +
                ", batteryLevel=" + batteryLevel +
                ", createdAt=" + createdAt +
                '}';
    }
}
