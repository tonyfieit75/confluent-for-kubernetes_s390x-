#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="confluent-platform"
RELEASE="confluent-operator"
CRD_DIR="./crds"

echo "=============================================="
echo " 🧹 Uninstalling Confluent Operator (CFK) s390x"
echo "=============================================="

# --- Step 1: Remove Helm release ---
echo "➡️  Removing Helm release: ${RELEASE}"
if helm status "${RELEASE}" -n "${NAMESPACE}" >/dev/null 2>&1; then
  helm uninstall "${RELEASE}" -n "${NAMESPACE}"
else
  echo "⚠️  Helm release ${RELEASE} not found, skipping uninstall."
fi

# --- Step 2: Delete CRDs ---
echo "➡️  Deleting Confluent CRDs..."
for f in ${CRD_DIR}/*.yaml; do
  CRD=$(grep "^  name:" "$f" | head -n 1 | awk '{print $2}')
  echo "   → Deleting CRD: ${CRD}"
  oc delete crd "${CRD}" --ignore-not-found=true
done

# --- Step 3: Delete namespace ---
echo "➡️  Deleting namespace: ${NAMESPACE}"
oc delete ns "${NAMESPACE}" --ignore-not-found=true

echo "=============================================="
echo " ✅ CFK s390x Uninstall Completed"
echo "=============================================="

exit 0

