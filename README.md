# JBoss EAP: VM to OpenShift Container Re-platforming

A complete, production-ready example of migrating JBoss EAP applications from
virtual machines to containers running on Red Hat OpenShift, following Red Hat
official guidance and best practices.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│  OpenShift Cluster                                              │
│                                                                 │
│  ┌──────────────┐    ┌──────────────────────────────────────┐   │
│  │  OpenShift    │    │  EAP Namespace                       │   │
│  │  Pipelines    │───▶│                                      │   │
│  │  (Tekton)     │    │  ┌────────────┐   ┌──────────────┐  │   │
│  └──────────────┘    │  │ EAP Operator│   │ EAP Pods (3) │  │   │
│                       │  │ (WildFlyS.. │──▶│  ┌─────────┐ │  │   │
│  ┌──────────────┐    │  │  erver CR)  │   │  │ EAP 8    │ │  │   │
│  │  Helm Chart   │    │  └────────────┘   │  │ Runtime  │ │  │   │
│  │  (bootstrap)  │    │                    │  └─────────┘ │  │   │
│  └──────────────┘    │  ┌────────────┐   └──────────────┘  │   │
│                       │  │  Route /    │                      │   │
│                       │  │  Service    │                      │   │
│                       │  └────────────┘                      │   │
│                       └──────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

## What's Included

| Directory       | Purpose                                                |
|-----------------|--------------------------------------------------------|
| `application/`  | Sample EAP 8 Jakarta EE 10 application (WAR)          |
| `s2i/`          | S2I (Source-to-Image) build configuration              |
| `operator/`     | EAP Operator CRs (WildFlyServer)                      |
| `helm/`         | Helm chart for full stack deployment                   |
| `cicd/`         | OpenShift Pipelines (Tekton) CI/CD                     |
| `openshift/`    | Kustomize overlays per environment                     |
| `scripts/`      | Helper scripts for migration and setup                 |

## Prerequisites

- OpenShift 4.14+ cluster with cluster-admin access
- `oc` CLI logged in to the cluster
- `helm` 3.x installed
- Access to `registry.redhat.io` (Red Hat container registry)
- Red Hat EAP 8 subscription entitlement

## Quick Start

### 1. Cluster Setup

```bash
# Install required operators and configure the registry
./scripts/setup-cluster.sh
```

### 2. Deploy with Helm (Recommended for Initial Setup)

```bash
# Create the namespace and deploy the full stack
helm install eap-demo ./helm \
  --namespace eap-demo \
  --create-namespace \
  --values helm/values-dev.yaml
```

### 3. Deploy with the EAP Operator (Production)

```bash
# Apply the operator CR directly
oc apply -k openshift/overlays/dev
```

### 4. Set Up CI/CD

```bash
# Install Tekton pipelines and triggers
oc apply -f cicd/pipelines/
oc apply -f cicd/tasks/
oc apply -f cicd/triggers/
```

## Migration Checklist (VM → Container)

- [ ] Externalize configuration (no hardcoded paths or IPs)
- [ ] Move persistent data to external services (DB, S3, etc.)
- [ ] Replace file-system logging with stdout/stderr
- [ ] Convert CLI scripts to EAP CLI boot scripts or env vars
- [ ] Replace multicast clustering with DNS_PING or KUBE_PING
- [ ] Convert JNDI datasources to env-var-driven configuration
- [ ] Remove any JVM tuning that conflicts with container limits
- [ ] Validate health/readiness probes map to EAP endpoints
- [ ] Test session replication across pod replicas

## Key Design Decisions

1. **EAP 8 on JDK 21** — aligns with Red Hat's long-term support track
2. **S2I builds** — uses Red Hat's official EAP 8 builder image
3. **EAP Operator (WildFlyServer CR)** — manages lifecycle, scaling, and
   session draining during rolling updates
4. **OpenShift Pipelines (Tekton)** — cluster-native CI/CD, no external
   Jenkins dependency
5. **Kustomize overlays** — environment-specific configuration without
   chart duplication
6. **KUBE_PING clustering** — Kubernetes-native JGroups discovery, no
   multicast required
# eap-demo
