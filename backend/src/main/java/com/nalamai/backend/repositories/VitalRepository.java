package com.nalamai.backend.repositories;

import com.nalamai.backend.models.User;
import com.nalamai.backend.models.Vital;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface VitalRepository extends JpaRepository<Vital, Long> {

    List<Vital> findByUser(User user);

    @Query("SELECT v FROM Vital v WHERE v.user.id = :userId")
    List<Vital> findByUserId(@Param("userId") Long userId);

    List<Vital> findByUserAndType(User user, String type);

    @Query("SELECT v FROM Vital v WHERE v.user.id = :userId AND v.type = :type")
    List<Vital> findByUserIdAndType(@Param("userId") Long userId, @Param("type") String type);

    @Query("SELECT v FROM Vital v WHERE v.user.id = :userId ORDER BY v.timestamp DESC")
    List<Vital> findByUserIdOrderByTimestampDesc(@Param("userId") Long userId);

    @Query("SELECT v FROM Vital v WHERE v.user.id = :userId AND v.type = :type ORDER BY v.timestamp DESC LIMIT 1")
    Optional<Vital> findLatestByUserIdAndType(@Param("userId") Long userId, @Param("type") String type);

    @Query("SELECT v FROM Vital v WHERE v.user.id = :userId ORDER BY v.timestamp DESC LIMIT 1")
    Optional<Vital> findLatestByUserId(@Param("userId") Long userId);
}
