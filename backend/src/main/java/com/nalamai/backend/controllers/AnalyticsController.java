package com.nalamai.backend.controllers;

import com.nalamai.backend.repositories.AppointmentRepository;
import com.nalamai.backend.repositories.BillingRepository;
import com.nalamai.backend.repositories.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/analytics")
@CrossOrigin(origins = "*")
public class AnalyticsController {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private AppointmentRepository appointmentRepository;

    @Autowired
    private BillingRepository billingRepository;

    @GetMapping("/summary")
    public Map<String, Object> getSystemSummary() {
        Map<String, Object> stats = new HashMap<>();
        
        long totalPatients = userRepository.count();
        long totalAppointments = appointmentRepository.count();
        
        Double totalRevenue = billingRepository.findAll()
                .stream()
                .mapToDouble(b -> b.getTotalAmount())
                .sum();

        stats.put("totalPatients", totalPatients);
        stats.put("totalAppointments", totalAppointments);
        stats.put("totalRevenue", totalRevenue);
        stats.put("currency", "USD");
        stats.put("status", "System Normal");

        return stats;
    }
}
