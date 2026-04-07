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
public class DocumentDTO {

    private Long id;
    private Long userId;
    private String fileName;
    private String fileType;
    private String fileUrl;
    private LocalDateTime uploadDate;
    private String documentType; // Prescription, LabReport, XRay, Other
}
