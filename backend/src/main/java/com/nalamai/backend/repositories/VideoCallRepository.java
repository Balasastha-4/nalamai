package com.nalamai.backend.repositories;

import com.nalamai.backend.models.User;
import com.nalamai.backend.models.VideoCall;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface VideoCallRepository extends JpaRepository<VideoCall, Long> {

    List<VideoCall> findByDoctor(User doctor);

    @Query("SELECT vc FROM VideoCall vc WHERE vc.doctor.id = :doctorId")
    List<VideoCall> findByDoctorId(@Param("doctorId") Long doctorId);

    List<VideoCall> findByPatient(User patient);

    @Query("SELECT vc FROM VideoCall vc WHERE vc.patient.id = :patientId")
    List<VideoCall> findByPatientId(@Param("patientId") Long patientId);

    Optional<VideoCall> findByRoomId(String roomId);

    @Query("SELECT vc FROM VideoCall vc WHERE vc.doctor.id = :doctorId ORDER BY vc.scheduledTime DESC")
    List<VideoCall> findByDoctorIdOrderByScheduledTimeDesc(@Param("doctorId") Long doctorId);

    @Query("SELECT vc FROM VideoCall vc WHERE vc.patient.id = :patientId ORDER BY vc.scheduledTime DESC")
    List<VideoCall> findByPatientIdOrderByScheduledTimeDesc(@Param("patientId") Long patientId);

    @Query("SELECT vc FROM VideoCall vc WHERE vc.status = :status")
    List<VideoCall> findByStatus(@Param("status") String status);
}
