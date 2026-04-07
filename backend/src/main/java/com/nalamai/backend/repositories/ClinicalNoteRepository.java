package com.nalamai.backend.repositories;

import com.nalamai.backend.models.ClinicalNote;
import com.nalamai.backend.models.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ClinicalNoteRepository extends JpaRepository<ClinicalNote, Long> {

    List<ClinicalNote> findByPatient(User patient);

    @Query("SELECT cn FROM ClinicalNote cn WHERE cn.patient.id = :patientId")
    List<ClinicalNote> findByPatientId(@Param("patientId") Long patientId);

    List<ClinicalNote> findByDoctor(User doctor);

    @Query("SELECT cn FROM ClinicalNote cn WHERE cn.doctor.id = :doctorId")
    List<ClinicalNote> findByDoctorId(@Param("doctorId") Long doctorId);

    List<ClinicalNote> findByPatientAndTag(User patient, String tag);

    @Query("SELECT cn FROM ClinicalNote cn WHERE cn.patient.id = :patientId AND cn.tag = :tag")
    List<ClinicalNote> findByPatientIdAndTag(@Param("patientId") Long patientId, @Param("tag") String tag);

    @Query("SELECT cn FROM ClinicalNote cn WHERE cn.patient.id = :patientId ORDER BY cn.createdAt DESC")
    List<ClinicalNote> findByPatientIdOrderByCreatedAtDesc(@Param("patientId") Long patientId);
}
