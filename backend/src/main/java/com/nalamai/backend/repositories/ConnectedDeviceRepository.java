package com.nalamai.backend.repositories;

import com.nalamai.backend.models.ConnectedDevice;
import com.nalamai.backend.models.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ConnectedDeviceRepository extends JpaRepository<ConnectedDevice, Long> {

    List<ConnectedDevice> findByUser(User user);

    @Query("SELECT cd FROM ConnectedDevice cd WHERE cd.user.id = :userId")
    List<ConnectedDevice> findByUserId(@Param("userId") Long userId);

    List<ConnectedDevice> findByUserAndIsConnected(User user, Boolean isConnected);

    @Query("SELECT cd FROM ConnectedDevice cd WHERE cd.user.id = :userId AND cd.isConnected = :isConnected")
    List<ConnectedDevice> findByUserIdAndIsConnected(@Param("userId") Long userId, @Param("isConnected") Boolean isConnected);
}
