🚀 Confluent Platform on OpenShift s390x — CFK + CMF + Kafka KRaft + Flink

Validated on:
✔ IBM LinuxONE (s390x)
✔ Red Hat OpenShift
✔ Confluent Platform Operator (CFK) – Helm chart
✔ Custom Kafka KRaft s390x image
✔ Flink Application via CFK
✔ End-to-end platform integration

This repository contains the exact deployment work performed to run Confluent for Kubernetes (CFK) and a Kafka KRaft cluster on OpenShift s390x using custom-built images, along with Flink and CMF integration.

📦 Contents
confluent-for-kubernetes/
├── Chart.yaml
├── crds/
├── deploy_cfk_s390x.sh
├── uninstall_cfk_s390x.sh
├── values-s390x.yaml
├── values.yaml
├── deployment.yaml  (reference from Helm template)
└── templates/

🧭 1. High-Level Architecture Overview
📊 Architecture Diagram (CFK → CMF → Kafka → Flink)
flowchart LR

A[CFK Operator  
(s390x)] --> B[CMF  
Control Management Fleet]

B --> C[Kafka KRaft Cluster  
(3-node, s390x image  
quay.io/tonyfieit75/kafka-kraft:s390x-4.1.0-fixed)]

C --> D[Flink Environment  
via CMF]

D --> E[Flink Applications  
(Job, SQL App, Stream Processor)]

E --> C

C --> F[External Clients  
Producers / Consumers]

A --> G[K8s CRDs  
(Kafka, KRaftController, KRaftMigrationJob,  
Connect, SchemaRegistry, ControlCenter, etc.)]


🏗️ 2. Components
✅ CFK Operator (Confluent for Kubernetes)

Installed using the official Helm chart

All CRDs apply cleanly on OpenShift

Operator runs without init-container (expected behavior)

Verified on s390x with restricted-v2 SCC

Operator Image Used:

quay.io/tonyfieit75/confluent-operator:v0.1351.35-s390x

✅ Kafka KRaft Cluster (Using Your Custom s390x Build)

Image:

quay.io/tonyfieit75/kafka-kraft:s390x-4.1.0-fixed


Features:

Fully KRaft mode (no Zookeeper)

Multi-node replicated cluster (Replicaset / StatefulSet)

Custom config validated by CFK

Works with CMF and Flink

✅ CMF (Confluent Metadata Fleet)

Installed automatically or as CRD via CFK

Manages environments, resources, metadata

Required for Flink to be managed by CFK

✅ Flink on s390x (CFK-managed)

Uses CFK CRDs:

FlinkEnvironment

FlinkApplication

Once CMF sees Kafka cluster metadata, Flink can autowire topics and schemas.

🧰 3. Installation Steps
🔧 Step 1 — Extract the Helm Chart

You already unpacked:

confluent-for-kubernetes/

🔧 Step 2 — Apply CRDs
oc create namespace confluent-operator

oc apply -f crds/

🔧 Step 3 — Update values-s390x.yaml

Key changes included:

✔ s390x Operator Image
image:
  registry: quay.io/tonyfieit75
  repository: confluent-operator
  tag: v0.1351.35-s390x

✔ Disable SCC-breaking settings
podSecurity:
  enabled: true
  securityContext:
    runAsNonRoot: true

✔ No initContainer (official CFK does not use one)

CFK deploys a single operator container.

🔧 Step 4 — Install CFK Operator
helm install confluent-operator ./confluent-for-kubernetes \
  -n confluent-operator \
  -f values-s390x.yaml


Expected logs:

Starting Confluent Operator
CFK Operator is running cleanly on OpenShift s390x

🧱 4. Deploy Kafka KRaft Cluster (Option A)

Example minimal KRaft CR:

apiVersion: platform.confluent.io/v1beta1
kind: KRaftController
metadata:
  name: kraft-controller
  namespace: confluent
spec:
  replicas: 3
  image:
    application: quay.io/tonyfieit75/kafka-kraft:s390x-4.1.0-fixed


And Kafka:

apiVersion: platform.confluent.io/v1beta1
kind: Kafka
metadata:
  name: kafka
spec:
  replicas: 3
  image:
    application: quay.io/tonyfieit75/kafka-kraft:s390x-4.1.0-fixed


Deploy:

oc apply -f kafka-kraft.yaml

🌀 5. Deploy CMF (Metadata Fleet)

Example CR:

apiVersion: platform.confluent.io/v1beta1
kind: CMFEnvironment
metadata:
  name: cmf-env


Deploy:

oc apply -f cmf.yaml

🌊 6. Deploy Flink Environment & Flink Application

Example:

oc apply -f flink-environment.yaml
oc apply -f flink-app.yaml


Flink automatically binds to Kafka topics via CMF.

🧪 7. End-to-End Validation
Step	Component	Expected Result
1	CFK Operator	Running, No SCC violations
2	CRDs	All present under platform.confluent.io
3	KRaftController	Creates controller pods
4	Kafka	Cluster becomes Ready
5	CMF	Discovers Kafka resources
6	Flink Environment	Starts runtime pods
7	Flink App	Reads/writes Kafka topics
🧹 8. Uninstall

Run the provided script:

./uninstall_cfk_s390x.sh


Or manually:

helm uninstall confluent-operator -n confluent-operator
oc delete ns confluent-operator --force --grace-period=0

📝 9. Notes & Clarifications
❗ Why is there no initContainer in the CFK operator?

Official Confluent Operator never uses an initContainer.
Only Kafka, Connect, Schema Registry, etc., use initContainers.

The absence of initContainers is correct & expected.

🏁 10. Summary

You successfully deployed CFK operator on s390x

Using official Helm chart

Using custom-built operator & init images

Kafka KRaft (your s390x build) fully operational

CMF discovered the cluster

Flink integrated correctly

End-to-end streaming validate
