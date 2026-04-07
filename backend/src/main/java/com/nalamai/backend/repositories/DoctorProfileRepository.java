package com.nalamai.backend.repositories;

import com.nalamai.backend.models.DoctorProfile;
import com.nalamai.backend.models.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface DoctorProfileRepository extends JpaRepository<DoctorProfile, Long> {

    Optional<DoctorProfile> findByUser(User user);

    @Query("SELECT dp FROM DoctorProfile dp WHERE dp.user.id = :userId")
    Optional<DoctorProfile> findByUserId(@Param("userId") Long userId);

    List<DoctorProfile> findBySpecialty(String specialty);

    @Query("SELECT dp FROM DoctorProfile dp WHERE LOWER(dp.specialty) = LOWER(:specialty)")
    List<DoctorProfile> findBySpecialtyIgnoreCase(@Param("specialty") String specialty);
}
