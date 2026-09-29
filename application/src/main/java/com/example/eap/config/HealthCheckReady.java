package com.example.eap.config;

import org.eclipse.microprofile.health.HealthCheck;
import org.eclipse.microprofile.health.HealthCheckResponse;
import org.eclipse.microprofile.health.Readiness;

import jakarta.enterprise.context.ApplicationScoped;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;

@Readiness
@ApplicationScoped
public class HealthCheckReady implements HealthCheck {

    @PersistenceContext
    private EntityManager em;

    @Override
    public HealthCheckResponse call() {
        try {
            em.createNativeQuery("SELECT 1").getSingleResult();
            return HealthCheckResponse.named("eap-demo-db-ready")
                    .up()
                    .build();
        } catch (Exception e) {
            return HealthCheckResponse.named("eap-demo-db-ready")
                    .down()
                    .withData("error", e.getMessage())
                    .build();
        }
    }
}
