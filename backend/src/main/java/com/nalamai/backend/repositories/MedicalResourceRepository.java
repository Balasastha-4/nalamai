package com.nalamai.backend.repositories;

import com.nalamai.backend.models.MedicalResource;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface MedicalResourceRepository extends JpaRepository<MedicalResource, Long> {
    List<MedicalResource> findByType(String type);
    List<MedicalResource> findByStatus(String status);
}
