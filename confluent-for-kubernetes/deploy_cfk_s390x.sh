#!/bin/bash

set -e

echo "=============================================="
echo " 🚀 Deploying Confluent Operator (CFK) s390x"
echo "=============================================="

NS="confluent-platform"

echo "➡️  Creating namespace: $NS"
oc create ns $NS 2>/dev/null || true

echo "➡️  Applying CRDs..."
for crd in ./crds/*.yaml; do
  echo "   → Applying CRD: $(basename $crd)"
  oc apply -f "$crd"
done

echo "➡️  Installing CFK operator via Helm..."
helm upgrade --install confluent-operator . \
  -n $NS \
  -f values-s390x.yaml

echo "✅ Deployment complete!"
echo ""
oc get pods -n $NS

