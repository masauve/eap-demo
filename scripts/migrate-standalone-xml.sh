#!/usr/bin/env bash
# =============================================================================
# Migration helper — extract configuration from VM-based standalone.xml
#
# When migrating from a VM-based EAP installation, this script helps identify
# configuration that needs to be externalized for container deployment.
#
# Usage:
#   ./scripts/migrate-standalone-xml.sh /path/to/standalone.xml
#
# It analyzes the XML and reports:
#   - Datasource definitions → environment variables
#   - JVM options → JAVA_OPTS_APPEND
#   - Logging configuration → container stdout/stderr
#   - Security domains → recommendations
#   - System properties → ConfigMap entries
#   - Deployment scanner config → not needed in containers
# =============================================================================
set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: $0 <path-to-standalone.xml>"
  exit 1
fi

STANDALONE_XML="$1"

if [ ! -f "$STANDALONE_XML" ]; then
  echo "ERROR: File not found: $STANDALONE_XML"
  exit 1
fi

echo "============================================="
echo "  EAP VM → Container Migration Analysis"
echo "============================================="
echo ""
echo "Source: $STANDALONE_XML"
echo ""

# --- Datasources ---
echo "--- DATASOURCES ---"
echo "Convert these to environment variables for the EAP datasources Galleon pack:"
echo ""
grep -oP 'jndi-name="[^"]*"' "$STANDALONE_XML" 2>/dev/null | while read -r line; do
  JNDI=$(echo "$line" | sed 's/jndi-name="//;s/"//')
  echo "  Found: $JNDI"
  echo "    → Set POSTGRESQL_SERVICE_HOST, POSTGRESQL_SERVICE_PORT, etc."
done
echo ""

# --- System Properties ---
echo "--- SYSTEM PROPERTIES ---"
echo "Move these to a ConfigMap or environment variables:"
echo ""
grep -oP '<property name="[^"]*" value="[^"]*"' "$STANDALONE_XML" 2>/dev/null | while read -r line; do
  echo "  $line"
done
echo ""

# --- Logging ---
echo "--- LOGGING ---"
echo "Container best practice: log to stdout/stderr, not files."
if grep -q 'periodic-rotating-file-handler\|size-rotating-file-handler\|file-handler' "$STANDALONE_XML" 2>/dev/null; then
  echo "  ⚠  File-based log handlers detected — remove these and rely on"
  echo "     the default CONSOLE handler. OpenShift collects stdout/stderr"
  echo "     via the cluster logging stack (Loki/Elasticsearch)."
  echo ""
  grep -oP 'name="[^"]*"' <(grep -A2 'file-handler' "$STANDALONE_XML") 2>/dev/null | head -5 | while read -r line; do
    echo "    Handler: $line"
  done
else
  echo "  ✓  No file-based log handlers found."
fi
echo ""

# --- JVM Options ---
echo "--- JVM OPTIONS ---"
echo "Let the container-aware JDK handle heap sizing. Remove explicit -Xmx/-Xms."
echo "Use JAVA_OPTS_APPEND for additional flags."
echo ""

# --- Deployment Scanner ---
if grep -q 'deployment-scanner' "$STANDALONE_XML" 2>/dev/null; then
  echo "--- DEPLOYMENT SCANNER ---"
  echo "  ⚠  Deployment scanner is not used in containers — the WAR is"
  echo "     baked into the image at build time. Remove this subsystem."
  echo ""
fi

# --- Security ---
echo "--- SECURITY ---"
if grep -q 'security-domain\|elytron' "$STANDALONE_XML" 2>/dev/null; then
  echo "  Security domains detected. Review these carefully:"
  grep -oP 'name="[^"]*"' <(grep 'security-domain' "$STANDALONE_XML") 2>/dev/null | sort -u | while read -r line; do
    echo "    Domain: $line"
  done
  echo ""
  echo "  Recommendations:"
  echo "    - Use EAP Elytron subsystem (not legacy security)"
  echo "    - For LDAP: configure via env vars or mounted elytron config"
  echo "    - For OIDC/SSO: use Red Hat SSO (Keycloak) with the OIDC adapter"
fi
echo ""

echo "============================================="
echo "  Analysis complete. Review above and update"
echo "  environment variables in:"
echo "    - operator/wildfly-server.yaml"
echo "    - helm/values.yaml"
echo "============================================="
