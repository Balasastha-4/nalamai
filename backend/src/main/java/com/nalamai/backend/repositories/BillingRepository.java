package com.nalamai.backend.repositories;

import com.nalamai.backend.models.Billing;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface BillingRepository extends JpaRepository<Billing, Long> {
    List<Billing> findByPatientId(Long patientId);
}
