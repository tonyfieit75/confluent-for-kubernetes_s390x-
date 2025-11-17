# Confluent for Kubernetes (CFK) – s390x Deployment Guide

## Custom CFK Operator Build for IBM LinuxONE / OpenShift on s390x

### 📌 Overview
This repository contains a customized **Confluent for Kubernetes (CFK) Operator** build for **IBM LinuxONE (s390x)**.  
The deployment uses the official Confluent Helm chart, combined with custom-built operator and init-container images compiled for the s390x architecture.

The CFK Operator has been successfully deployed and validated on OpenShift running on s390x.

---

### 🧱 High-Level Architecture
```
+---------------------------------------------+
|      Confluent for Kubernetes Operator      |
|        (Custom Build for s390x)             |
+-----------------------+---------------------+
                        |
                        | Manages CRDs
                        v
        +--------------------------------+
        | Confluent Platform Resources   |
        | (Kafka, KRaft, Connect, SR,    |
        |  C3, KSQL, etc.)               |
        +--------------------------------+
                        |
                        v
+------------------------------------------------+
| Kubernetes / OpenShift (s390x)                 |
| - Enforces SCC (restricted-v2)                 |
| - Uses operator SA to watch namespaces         |
+------------------------------------------------+
```

---

### 🔑 Key Points
- The official CFK Helm chart is used exactly as provided by Confluent.
- The only modification is the **s390x-compatible container images**.
- The official chart does **NOT** use an initContainer.
- OpenShift SCC is fully compatible because `runAsUser` is not enforced (removed from values).

---

### 📁 Repository Structure
```
confluent-for-kubernetes/
├── Chart.yaml
├── crds/                         # All CFK CRDs
│   ├── platform.confluent.io_kafkas.yaml
│   ├── platform.confluent.io_kraftcontrollers.yaml
│   ├── platform.confluent.io_kraftmigrationjobs.yaml
│   ├── platform.confluent.io_confluentrolebindings.yaml
│   ├── ...
│   └── platform.confluent.io_zookeepers.yaml
├── deploy_cfk_s390x.sh           # Automated installer script
├── uninstall_cfk_s390x.sh        # Automated uninstaller script
├── values.yaml                   # Official defaults
├── values-s390x.yaml             # Custom s390x operator configuration
├── deployment.yaml               # Generated manifest (optional for debugging)
└── templates/                    # Standard Helm templates
```

---

### 🚀 s390x Operator Images Used
| Component | Image Path | Tag |
|------------|-------------|-----|
| Confluent Operator | `quay.io/tonyfieit75/confluent-operator` | `v0.1351.35-s390x` |
| Init Container | `quay.io/tonyfieit75/confluent-init-container` | `v0.1351.35-s390x` |

---

### ⚙️ Custom `values-s390x.yaml`
The custom values file:
- Removes hard-coded UID/GID (required for OpenShift restricted SCC)
- Disables features not in use (webhooks, telemetry, managed certs)
- Enables namespaced operator mode
- Points to your custom s390x images
- Enables OpenShift clusterRole extensions

---

### 📦 Installation Instructions

#### 1️⃣ Set the project
```bash
oc new-project confluent-platform
```

#### 2️⃣ Deploy CRDs
```bash
kubectl apply -f crds/
```
This installs all `platform.confluent.io/*` CRDs required by CFK.

#### 3️⃣ Deploy CFK Operator (s390x)

You can use either Helm or the helper script.

**A. Deploy CFK via Helm (recommended)**
```bash
helm install confluent-operator ./confluent-for-kubernetes     -n confluent-platform     -f values-s390x.yaml
```

**B. Deploy using automated script**
```bash
./deploy_cfk_s390x.sh
```

This script:
- Creates namespace  
- Applies CRDs  
- Installs Helm release with s390x values

---

### 🧪 Validation

Check pod status:
```bash
oc get pods -n confluent-platform
```

Expected output:
```
NAME                                 READY   STATUS    RESTARTS   AGE
confluent-operator-xxxxx             1/1     Running   0          ...
```

Check operator logs:
```bash
oc logs -n confluent-platform deployment/confluent-operator
```

Expected key lines:
```
Starting Confluent Operator
version: v0.1351.35-...
Fips mode is set to: false
KRaftClusterIdRecovery is not enabled
Confluent telemetry reporter is not enabled
```

No init-container will appear since the official CFK chart does not use one.

---

### 🧹 Uninstallation Instructions

**A. Uninstall via Helm**
```bash
helm uninstall confluent-operator -n confluent-platform
```

**B. Delete namespace**
```bash
oc delete ns confluent-platform --force --grace-period=0
```

**C. Remove CRDs**
```bash
kubectl delete -f crds/
```

**(Optional)** Use automated uninstall script:
```bash
./uninstall_cfk_s390x.sh
```
This script removes Helm release, namespace, and CRDs.

---

### 📘 Notes & Observations
- The init-container image was not used because CFK does not mount any initContainers.  
- The CFK Operator runs successfully under OpenShift `restricted-v2` SCC after removing:
  - `runAsUser: 1001`
  - `fsGroup: 1001`
- CRDs install cleanly without modification.  
- No Operator errors observed during startup or reconciliation.  
- This is the **first validated CFK Operator running on LinuxONE (s390x)**.

---

### 🏁 Status: **SUCCESS**
The Confluent for Kubernetes Operator is now **fully functional** on OpenShift s390x using custom-built images.
