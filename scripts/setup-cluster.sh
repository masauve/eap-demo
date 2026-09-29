#!/usr/bin/env bash
# =============================================================================
# Cluster setup — installs prerequisites for EAP on OpenShift
#
# Prerequisites:
#   - oc CLI logged in as cluster-admin
#   - Access to registry.redhat.io (pull secret configured)
#
# This script:
#   1. Discovers the correct EAP operator package name from the catalog
#   2. Installs the EAP Operator from OperatorHub
#   3. Installs OpenShift Pipelines (Tekton) operator
#   4. Imports EAP 8 builder/runtime ImageStreams
#   5. Enables user-workload monitoring for ServiceMonitor support
# =============================================================================
set -euo pipefail

echo "=== Step 1: Discover and Install EAP Operator ==="

# Auto-detect the EAP operator package name — it varies by OCP version
EAP_PKG=$(oc get packagemanifests -n openshift-marketplace -o name 2>/dev/null \
  | grep -i eap | head -1 | sed 's|packagemanifest.packages.operators.coreos.com/||')

if [ -z "$EAP_PKG" ]; then
  echo "ERROR: No EAP package found in the catalog."
  echo ""
  echo "Verify your catalog sources are healthy:"
  echo "  oc get catalogsource -n openshift-marketplace"
  echo ""
  echo "Verify your cluster has the Red Hat Operators catalog:"
  echo "  oc get catalogsource redhat-operators -n openshift-marketplace -o yaml"
  echo ""
  echo "If the catalog is missing, check your cluster pull secret includes"
  echo "registry.redhat.io credentials."
  exit 1
fi

echo "Found EAP operator package: ${EAP_PKG}"

# Discover the default channel
EAP_CHANNEL=$(oc get packagemanifest "$EAP_PKG" -n openshift-marketplace \
  -o jsonpath='{.status.defaultChannel}')
echo "Using channel: ${EAP_CHANNEL}"

# The openshift-operators namespace already has a global OperatorGroup —
# do NOT create another one (OLM allows only one per namespace)
cat <<EOF | oc apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: eap
  namespace: openshift-operators
spec:
  channel: ${EAP_CHANNEL}
  installPlanApproval: Automatic
  name: ${EAP_PKG}
  source: redhat-operators
  sourceNamespace: openshift-marketplace
EOF

echo "Waiting for EAP Operator CSV to install..."

# Wait for the Subscription to report an installed CSV
for i in $(seq 1 60); do
  CSV=$(oc get subscription eap -n openshift-operators \
    -o jsonpath='{.status.installedCSV}' 2>/dev/null || true)
  if [ -n "$CSV" ]; then
    echo "  Installed CSV: $CSV"
    break
  fi
  echo "  Waiting for CSV to be installed... (${i}/60)"
  sleep 5
done

if [ -z "$CSV" ]; then
  echo "ERROR: Timed out waiting for EAP operator CSV."
  echo "Check subscription status:"
  echo "  oc describe subscription eap -n openshift-operators"
  exit 1
fi

# Wait for the CSV to reach Succeeded phase
oc wait csv/"$CSV" -n openshift-operators \
  --for=jsonpath='{.status.phase}'=Succeeded \
  --timeout=300s

echo "EAP Operator is installed and ready."

# Verify the CRD is available
if oc get crd wildflyservers.wildfly.org &>/dev/null; then
  echo "WildFlyServer CRD is registered."
else
  echo "WARNING: WildFlyServer CRD not found — check the CSV status."
fi

echo ""
echo "=== Step 2: Install OpenShift Pipelines Operator ==="
cat <<EOF | oc apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: openshift-pipelines-operator
  namespace: openshift-operators
spec:
  channel: latest
  name: openshift-pipelines-operator-rh
  source: redhat-operators
  sourceNamespace: openshift-marketplace
  installPlanApproval: Automatic
EOF

echo "Waiting for Pipelines operator..."
for i in $(seq 1 60); do
  if oc get crd pipelines.tekton.dev &>/dev/null; then
    echo "Tekton Pipelines CRD is available."
    break
  fi
  echo "  Waiting for Tekton CRD... (${i}/60)"
  sleep 5
done

echo ""
echo "=== Step 3: Import EAP 8 ImageStreams ==="
oc import-image jboss-eap8-openjdk21-openshift:latest \
  --from=registry.redhat.io/jboss-eap-8/eap8-openjdk21-builder-openshift-rhel9:latest \
  --confirm -n openshift 2>/dev/null || echo "ImageStream may already exist"

oc import-image jboss-eap8-openjdk21-runtime-openshift:latest \
  --from=registry.redhat.io/jboss-eap-8/eap8-openjdk21-runtime-openshift-rhel9:latest \
  --confirm -n openshift 2>/dev/null || echo "ImageStream may already exist"

echo ""
echo "=== Step 4: Enable User Workload Monitoring ==="
oc apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: cluster-monitoring-config
  namespace: openshift-monitoring
data:
  config.yaml: |
    enableUserWorkload: true
EOF

echo ""
echo "=== Setup Complete ==="
echo ""
echo "Next steps:"
echo "  1. Create your namespace:    oc new-project eap-demo"
echo "  2. Deploy with Helm:         helm install eap-demo ./helm --values helm/values-dev.yaml"
echo "  3. Or deploy with Kustomize: oc apply -k openshift/overlays/dev"
echo "  4. Set up CI/CD:             oc apply -f cicd/"
