package com.nalamai.backend.repositories;

import com.nalamai.backend.models.Alert;
import com.nalamai.backend.models.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface AlertRepository extends JpaRepository<Alert, Long> {

    List<Alert> findByUser(User user);

    @Query("SELECT a FROM Alert a WHERE a.user.id = :userId")
    List<Alert> findByUserId(@Param("userId") Long userId);

    List<Alert> findByUserAndIsResolved(User user, Boolean isResolved);

    @Query("SELECT a FROM Alert a WHERE a.user.id = :userId AND a.isResolved = :isResolved")
    List<Alert> findByUserIdAndIsResolved(@Param("userId") Long userId, @Param("isResolved") Boolean isResolved);

    @Query("SELECT a FROM Alert a WHERE a.user.id = :userId ORDER BY a.createdAt DESC")
    List<Alert> findByUserIdOrderByCreatedAtDesc(@Param("userId") Long userId);

    @Query("SELECT a FROM Alert a WHERE a.user.id = :userId AND a.isResolved = false ORDER BY a.createdAt DESC")
    List<Alert> findUnreadByUserId(@Param("userId") Long userId);
}
