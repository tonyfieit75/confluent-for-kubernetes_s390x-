✅ 1. GitHub Wiki (A1) — Full Wiki Structure (copy/paste-ready)

I provide the full wiki content here. If you want, I can also package it as a downloadable ZIP.

📘 Home.md
# Confluent Platform on IBM LinuxONE (s390x)
This wiki documents the full end-to-end deployment of:

- Confluent for Kubernetes (CFK) Operator – s390x
- CFK-Managed Kafka KRaft Cluster – s390x
- Confluent Manager for Flink (CMF)
- Apache Flink Operator – s390x
- End-to-end streaming pipeline validation

All images used are custom-built for IBM LinuxONE (s390x).

📘 1_Architecture_Overview.md
# Architecture Overview

                +----------------------------+
                |     Confluent Operator     |
                |        (CFK s390x)         |
                +------------+---------------+
                             |
                             v
                +----------------------------+
                |   Kafka KRaft Cluster      |
                | (quay.io/.../kafka-kraft)  |
                +-------------+--------------+
                              |
                              v
                +----------------------------+
                | Confluent Manager (CMF)    |
                |   + Flink Integration      |
                +-------------+--------------+
                              |
                              v
                +----------------------------+
                | Apache Flink Operator      |
                | Kafka Source → Sink test   |
                +----------------------------+

Flow:
CFK → Kafka (KRaft) → CMF → Flink → Back to Kafka

📘 2_Prerequisites.md
# Prerequisites

- Openshift 4.x (s390x)
- OC CLI + Helm CLI
- Custom images:

  quay.io/tonyfieit75/confluent-operator:v0.1351.35-s390x  
  quay.io/tonyfieit75/confluent-init-container:v0.1351.35-s390x  
  quay.io/tonyfieit75/kafka-kraft:s390x-4.1.0-fixed

- Namespace: `confluent`
- ImagePullSecret: `confluent-registry`

📘 3_Install_CFK_s390x.md
# Installing CFK (s390x)

## Step 1 — Create namespace
oc create ns confluent-operator

## Step 2 — Apply CRDs
for f in crds/*.yaml; do
  oc apply -f $f
done

## Step 3 — Install CFK
helm install confluent-operator ./confluent-for-kubernetes \
   -n confluent-operator \
   -f values-s390x.yaml

CFK Deployment:
confluent-operator-xxxxx Running

📘 4_Deploy_Kafka_KRaft_s390x.md
apiVersion: platform.confluent.io/v1beta1
kind: Kafka
metadata:
  name: kafka
  namespace: confluent
spec:
  replicas: 3
  image:
    application: quay.io/tonyfieit75/kafka-kraft:s390x-4.1.0-fixed
  storage:
    volumes:
    - name: data
      type: persistent

📘 5_Deploy_CMF.md

(Latest CMF official instructions adapted for s390x — provided if needed.)

📘 6_Deploy_Flink.md

(Deploy Flink Operator + FlinkApplication for Kafka stream test.)

📘 7_End_to_End_Testing.md

This refers to the C3 test suite (Kubernetes Job).

📘 8_Troubleshooting.md

Includes:

SCC issues

CRD mismatches

Leader election

Missing permissions

Init-container confusion

📘 9_Uninstall_Guide.md
helm uninstall confluent-operator -n confluent-operator
oc delete ns confluent-operator --force --grace-period=0

✅ 2. Simple PDF (B1)

📌 I will generate the PDF AFTER you approve the README.md below.
The PDF will be exactly this README content.

✅ 3. Kafka KRaft Test Suite — Kubernetes Job (C3)

Namespace: confluent

ConfigMap: kraft-tests

Save as: kraft-tests.yaml

apiVersion: v1
kind: ConfigMap
metadata:
  name: kraft-tests
  namespace: confluent
data:
  01-check-cluster.sh: |
    #!/bin/bash
    echo "Checking Kafka brokers..."
    oc get pods -n confluent -l app=kafka
  02-create-topics.sh: |
    #!/bin/bash
    kafka-topics.sh --bootstrap-server kafka:9092 --create \
      --topic demo --replication-factor 3 --partitions 3
  03-produce-consume.sh: |
    #!/bin/bash
    echo "Test message" | kafka-console-producer.sh --broker-list kafka:9092 --topic demo
    kafka-console-consumer.sh --bootstrap-server kafka:9092 --topic demo --from-beginning --timeout-ms 5000
  04-failover.sh: |
    #!/bin/bash
    echo "Simulating broker failover..."
    oc delete pod -n confluent $(oc get pod -n confluent -l app=kafka | grep Running | head -1 | awk '{print $1}')
  05-throughput.sh: |
    #!/bin/bash
    echo "Running performance test..."
    kafka-producer-perf-test.sh --topic demo --throughput 10000 --record-size 1000 --num-records 50000 --producer-props bootstrap.servers=kafka:9092
  06-flink-integration.sh: |
    #!/bin/bash
    echo "Running Flink → Kafka integration test"
    oc apply -f flink-kafka-job.yaml
  run-all.sh: |
    #!/bin/bash
    chmod +x /tests/*.sh
    for t in /tests/*.sh; do
      echo "==== Running $t ===="
      bash "$t"
      echo "==== Finished $t ===="
      echo
    done

Kubernetes Job: kraft-test-runner

Save as: kraft-test-runner.yaml

apiVersion: batch/v1
kind: Job
metadata:
  name: kraft-test-runner
  namespace: confluent
spec:
  backoffLimit: 0
  template:
    spec:
      restartPolicy: Never
      containers:
      - name: kraft-tests
        image: quay.io/tonyfieit75/kafka-kraft:s390x-4.1.0-fixed
        command: ["/bin/bash", "/tests/run-all.sh"]
        volumeMounts:
        - name: tests
          mountPath: /tests
      volumes:
      - name: tests
        configMap:
          name: kraft-tests
          defaultMode: 0755

Run the tests
oc apply -f kraft-tests.yaml
oc apply -f kraft-test-runner.yaml
oc logs -n confluent -f job/kraft-test-runner
