#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="confluent-operator"
YAML_FILE="kraftcontroller.yaml"

echo "📦 Deploying KRaftController into namespace: ${NAMESPACE}"
echo "➡ Applying ${YAML_FILE}..."
oc apply -n "${NAMESPACE}" -f "${YAML_FILE}"

echo "⏳ Waiting for KRaftController pods to start..."
oc wait pod -n "${NAMESPACE}" -l app=kraft-controller --for=condition=Initialized --timeout=180s || true

echo "⏳ Waiting for pods to be Running..."
oc wait pod -n "${NAMESPACE}" -l app=kraft-controller --for=condition=Ready --timeout=300s || true

echo "📋 Current pod status:"
oc get pods -n "${NAMESPACE}" -l app=kraft-controller

echo "✅ KRaftController installation complete!"

