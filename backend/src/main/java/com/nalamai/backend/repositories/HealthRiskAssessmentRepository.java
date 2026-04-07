package com.nalamai.backend.repositories;

import com.nalamai.backend.models.HealthRiskAssessment;
import com.nalamai.backend.models.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface HealthRiskAssessmentRepository extends JpaRepository<HealthRiskAssessment, Long> {

    List<HealthRiskAssessment> findByPatientOrderByCreatedAtDesc(User patient);

    Optional<HealthRiskAssessment> findFirstByPatientOrderByCreatedAtDesc(User patient);

    List<HealthRiskAssessment> findByPatientAndStatus(User patient, String status);

    List<HealthRiskAssessment> findByStatus(String status);

    @Query("SELECT h FROM HealthRiskAssessment h WHERE h.patient.id = :patientId ORDER BY h.createdAt DESC")
    List<HealthRiskAssessment> findByPatientId(@Param("patientId") Long patientId);

    @Query("SELECT h FROM HealthRiskAssessment h WHERE h.patient.id = :patientId AND h.createdAt >= :since ORDER BY h.createdAt DESC")
    List<HealthRiskAssessment> findRecentByPatientId(@Param("patientId") Long patientId, @Param("since") LocalDateTime since);

    @Query("SELECT h FROM HealthRiskAssessment h WHERE h.status = 'SUBMITTED' AND h.validatedDate IS NULL")
    List<HealthRiskAssessment> findPendingValidation();

    @Query("SELECT h FROM HealthRiskAssessment h WHERE h.overallRisk >= :threshold")
    List<HealthRiskAssessment> findHighRiskPatients(@Param("threshold") Integer threshold);

    @Query("SELECT COUNT(h) FROM HealthRiskAssessment h WHERE h.patient.id = :patientId AND h.createdAt >= :since")
    Long countRecentAssessments(@Param("patientId") Long patientId, @Param("since") LocalDateTime since);
}
