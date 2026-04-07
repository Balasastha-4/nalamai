package com.nalamai.backend.dtos;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.NotBlank;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CreateVitalRequest {

    @NotNull(message = "User ID is required")
    private Long userId;

    @NotBlank(message = "Type is required")
    private String type; // HeartRate, BP, SpO2, Temperature, Weight, BMI

    @NotNull(message = "Value is required")
    private Double value;

    private String unit;

    private Boolean isAlert;
}
