package com.example.eap.config;

import org.eclipse.microprofile.health.HealthCheck;
import org.eclipse.microprofile.health.HealthCheckResponse;
import org.eclipse.microprofile.health.Liveness;

import jakarta.enterprise.context.ApplicationScoped;

@Liveness
@ApplicationScoped
public class HealthCheckLive implements HealthCheck {

    @Override
    public HealthCheckResponse call() {
        return HealthCheckResponse.named("eap-demo-live")
                .up()
                .build();
    }
}
