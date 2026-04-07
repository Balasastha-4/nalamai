package com.nalamai.backend.dtos;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@JsonInclude(JsonInclude.Include.NON_NULL)
public class AppointmentDTO {

    private Long id;
    private Long patientId;
    private String patientName;
    private String patientEmail;
    private String patientPhone;
    private Long doctorId;
    private String doctorName;
    private String doctorEmail;
    private String doctorSpecialty;
    private LocalDateTime appointmentTime;
    private String status; // SCHEDULED, COMPLETED, CANCELLED
    private Long resourceId;
    private String resourceName;
    private String notes;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
