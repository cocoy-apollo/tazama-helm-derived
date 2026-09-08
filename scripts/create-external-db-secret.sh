#!/bin/bash
# create-external-db-secret.sh
# Creates Kubernetes Secret for external PostgreSQL database credentials
# 
# Usage: ./create-external-db-secret.sh [namespace]
#
# Prerequisites:
# - kubectl configured with cluster access
# - Namespace 'tazama' (or specified namespace) must exist
#
# Default credentials (modify as needed):
# - Username: postgres
# - Password: db2f-6dc5-4db4-942

set -e

NAMESPACE="${1:-tazama}"
USERNAME="${2:-postgres}"
PASSWORD="${3:-db2f-6dc5-4db4-942}"

echo "Creating database credentials secret in namespace: $NAMESPACE"
echo "Username: $USERNAME"
echo "Password: $PASSWORD"
echo ""

# Check if namespace exists
if ! kubectl get namespace "$NAMESPACE" >/dev/null 2>&1; then
    echo "Error: Namespace '$NAMESPACE' does not exist."
    echo "Create it with: kubectl create namespace $NAMESPACE"
    exit 1
fi

# Create the secret with all required database credentials
kubectl create secret generic tazama-shared-secrets \
    --from-literal=CONFIGURATION_DATABASE_USER="$USERNAME" \
    --from-literal=CONFIGURATION_DATABASE_PASSWORD="$PASSWORD" \
    --from-literal=EVENT_HISTORY_DATABASE_USER="$USERNAME" \
    --from-literal=EVENT_HISTORY_DATABASE_PASSWORD="$PASSWORD" \
    --from-literal=EVALUATION_DATABASE_USER="$USERNAME" \
    --from-literal=EVALUATION_DATABASE_PASSWORD="$PASSWORD" \
    --from-literal=RAW_HISTORY_DATABASE_USER="$USERNAME" \
    --from-literal=RAW_HISTORY_DATABASE_PASSWORD="$PASSWORD" \
    -n "$NAMESPACE"

echo ""
echo "Secret 'tazama-shared-secrets' created successfully in namespace '$NAMESPACE'"
echo ""
echo "You can now install the chart with:"
echo "  helm install tazama ./tazama-1.0.0.tgz -n $NAMESPACE -f values-external-db.yaml"
