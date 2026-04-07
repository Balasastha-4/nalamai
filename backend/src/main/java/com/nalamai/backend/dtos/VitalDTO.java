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
public class VitalDTO {

    private Long id;
    private Long userId;
    private String userName;
    private String type; // HeartRate, BP, SpO2, Temperature, Weight, BMI
    private Double value;
    private String unit;
    private Boolean isAlert;
    private LocalDateTime timestamp;
    private LocalDateTime createdAt;
}
