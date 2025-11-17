#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="confluent-operator"
RESOURCE="kraft-controller"

echo "🗑️ Removing KRaftController: ${RESOURCE} (namespace: ${NAMESPACE})"
oc delete kraftcontroller "${RESOURCE}" -n "${NAMESPACE}" --ignore-not-found

echo "⏳ Waiting for StatefulSet to terminate..."
oc delete statefulset "${RESOURCE}" -n "${NAMESPACE}" --ignore-not-found || true

echo "🧹 Cleaning PVCs for ${RESOURCE}..."
PVC_LIST=$(oc get pvc -n "${NAMESPACE}" -o name | grep "${RESOURCE}" || true)

if [[ -z "${PVC_LIST}" ]]; then
    echo "ℹ️ No PVCs found for ${RESOURCE}."
else
    echo "${PVC_LIST}" | xargs oc delete -n "${NAMESPACE}"
fi

echo "🧼 Cleaning leftover pods..."
oc delete pod -n "${NAMESPACE}" -l app=kraft-controller --ignore-not-found

echo "🧽 Clean-up of PVs (optional, uncomment if needed)"
# PV_LIST=$(oc get pv -o name | grep "${RESOURCE}" || true)
# if [[ -n "${PV_LIST}" ]]; then
#     echo "${PV_LIST}" | xargs oc delete
# fi

echo "📋 Verify resources removed:"
oc get pods -n "${NAMESPACE}" | grep kraft-controller || echo "No pods found."
oc get pvc -n "${NAMESPACE}" | grep kraft-controller || echo "No PVCs found."

echo "✅ KRaftController uninstallation complete!"

