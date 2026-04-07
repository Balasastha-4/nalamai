package com.nalamai.backend.dtos;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UpdateAppointmentRequest {

    private String status; // SCHEDULED, COMPLETED, CANCELLED

    private LocalDateTime appointmentTime;

    private String notes;
}
