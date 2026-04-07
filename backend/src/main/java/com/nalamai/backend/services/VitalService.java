package com.nalamai.backend.services;

import com.nalamai.backend.dtos.CreateVitalRequest;
import com.nalamai.backend.dtos.VitalDTO;
import com.nalamai.backend.models.User;
import com.nalamai.backend.models.Vital;
import com.nalamai.backend.repositories.UserRepository;
import com.nalamai.backend.repositories.VitalRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Slf4j
@Service
@Transactional
public class VitalService {

    @Autowired
    private VitalRepository vitalRepository;

    @Autowired
    private UserRepository userRepository;

    /**
     * Get all vitals for a patient, optionally filtered by type and date range
     */
    public List<VitalDTO> getPatientVitals(Long patientId, String type, Integer days) {
        List<Vital> vitals;

        if (type != null && !type.isEmpty()) {
            vitals = vitalRepository.findByUserIdAndType(patientId, type);
        } else {
            vitals = vitalRepository.findByUserIdOrderByTimestampDesc(patientId);
        }

        // Filter by days if provided
        int daysToFilter = days != null ? days : 30;
        LocalDateTime cutoffDate = LocalDateTime.now().minusDays(daysToFilter);

        return vitals.stream()
                .filter(v -> v.getTimestamp().isAfter(cutoffDate))
                .sorted((v1, v2) -> v2.getTimestamp().compareTo(v1.getTimestamp())) // Descending order
                .map(this::convertToDTO)
                .collect(Collectors.toList());
    }

    /**
     * Get latest vital readings for a patient
     */
    public List<VitalDTO> getLatestVitals(Long patientId) {
        List<String> vitalTypes = List.of("HeartRate", "BloodPressure", "SpO2", "Temperature", "Weight");
        return vitalTypes.stream()
                .map(type -> vitalRepository.findLatestByUserIdAndType(patientId, type))
                .filter(java.util.Optional::isPresent)
                .map(java.util.Optional::get)
                .map(this::convertToDTO)
                .collect(Collectors.toList());
    }

    /**
     * Record a new vital sign
     */
    public VitalDTO recordVital(CreateVitalRequest request) {
        User user = userRepository.findById(request.getUserId())
                .orElseThrow(() -> new RuntimeException("User not found with ID: " + request.getUserId()));

        Vital vital = new Vital();
        vital.setUser(user);
        vital.setType(request.getType());
        vital.setValue(request.getValue());
        vital.setUnit(request.getUnit());
        vital.setIsAlert(request.getIsAlert() != null ? request.getIsAlert() : false);
        vital.setTimestamp(LocalDateTime.now());

        Vital savedVital = vitalRepository.save(vital);
        log.info("Vital recorded: ID={}, User={}, Type={}, Value={}",
                savedVital.getId(), user.getId(), request.getType(), request.getValue());

        return convertToDTO(savedVital);
    }

    /**
     * Get trend data for a specific vital type
     */
    public List<VitalDTO> getVitalTrend(Long patientId, String type) {
        List<Vital> vitals = vitalRepository.findByUserIdAndType(patientId, type);

        return vitals.stream()
                .sorted((v1, v2) -> v1.getTimestamp().compareTo(v2.getTimestamp())) // Ascending order for trends
                .map(this::convertToDTO)
                .collect(Collectors.toList());
    }

    /**
     * Convert Vital entity to DTO
     */
    private VitalDTO convertToDTO(Vital vital) {
        return VitalDTO.builder()
                .id(vital.getId())
                .userId(vital.getUser().getId())
                .userName(vital.getUser().getName())
                .type(vital.getType())
                .value(vital.getValue())
                .unit(vital.getUnit())
                .isAlert(vital.getIsAlert())
                .timestamp(vital.getTimestamp())
                .createdAt(vital.getCreatedAt())
                .build();
    }
}
