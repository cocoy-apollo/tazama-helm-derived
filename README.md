# Tazama Helm Chart

A flexible Helm chart for deploying the Tazama financial crime detection platform with support for both internal and external infrastructure components.

## Table of Contents

- [Key Concepts](#key-concepts)
- [Infrastructure Options](#infrastructure-options)
- [Installation](#installation)
- [Configuration Reference](#configuration-reference)
- [Examples](#examples)
- [Troubleshooting](#troubleshooting)

---

## Key Concepts

This chart supports **flexible infrastructure deployment**:

1. **Internal Mode** (default): All infrastructure (PostgreSQL, Valkey/Redis, NATS) deployed in-cluster
2. **External Mode**: Connect to managed services (AWS RDS, ElastiCache, cloud NATS)
3. **Hybrid Mode**: Mix internal and external services as needed

### Design Principles

- **Backward Compatible**: Default values preserve existing behavior
- **Mutual Exclusion**: Internal and external modes for each component are mutually exclusive (validated at install)
- **Credential Hygiene**: No secrets in values.yaml - reference Kubernetes Secrets
- **Production Ready**: TLS enforcement, credential validation, helpful error messages

---

## Infrastructure Options

### PostgreSQL (Database)

| Parameter | Default | Description |
|-----------|---------|-------------|
| `infrastructure.postgres.enabled` | `true` | Deploy internal PostgreSQL |
| `infrastructure.postgres.external.enabled` | `false` | Use external PostgreSQL |
| `infrastructure.postgres.external.host` | `""` | External PostgreSQL host (required if external enabled) |
| `infrastructure.postgres.external.port` | `5432` | External PostgreSQL port |
| `infrastructure.postgres.external.database` | `tazama` | Database name |
| `infrastructure.postgres.external.secretRef.name` | `""` | Secret containing `user`, `password` |
| `infrastructure.postgres.external.ssl.enabled` | `true` | Enable TLS |
| `infrastructure.postgres.external.ssl.skipVerify` | `false` | Skip certificate verification (dev only) |

### Valkey / Redis (Cache)

| Parameter | Default | Description |
|-----------|---------|-------------|
| `infrastructure.valkey.enabled` | `true` | Deploy internal Valkey |
| `infrastructure.valkey.external.enabled` | `false` | Use external Valkey/Redis |
| `infrastructure.valkey.external.host` | `""` | External host (required if external enabled) |
| `infrastructure.valkey.external.port` | `6379` | External port |
| `infrastructure.valkey.external.secretRef.name` | `""` | Secret containing `password` |
| `infrastructure.valkey.external.cluster.enabled` | `false` | Enable cluster mode |
| `infrastructure.valkey.external.ssl.enabled` | `true` | Enable TLS |

### NATS (Message Broker)

| Parameter | Default | Description |
|-----------|---------|-------------|
| `infrastructure.nats.enabled` | `true` | Deploy internal NATS |
| `infrastructure.nats.jetStream.enabled` | `true` | Enable JetStream persistence |
| `infrastructure.nats.jetStream.storageSize` | `5Gi` | PVC size for JetStream |
| `infrastructure.nats.jetStream.maxMemory` | `512Mi` | Max memory for stream storage |
| `infrastructure.nats.jetStream.maxStore` | `2Gi` | Max disk storage for streams |
| `infrastructure.nats.external.enabled` | `false` | Use external NATS |
| `infrastructure.nats.external.host` | `""` | Single external host |
| `infrastructure.nats.external.port` | `4222` | External port |
| `infrastructure.nats.external.cluster.enabled` | `false` | Enable cluster mode |
| `infrastructure.nats.external.cluster.urls` | `[]` | List of cluster URLs |
| `infrastructure.nats.external.secretRef.name` | `""` | Secret containing credentials |

---

## Installation

### Prerequisites

- Kubernetes 1.19+
- Helm 3.8+
- `kubectl` configured to access your cluster

### Step 1: Prepare Secrets (External Mode Only)

If using external infrastructure, create Kubernetes secrets:

```bash
# PostgreSQL credentials
kubectl create secret generic rds-credentials \
  --from-literal=user=tazama_admin \
  --from-literal-password=<secure-password>

# Valkey/Redis credentials
kubectl create secret generic elasticache-credentials \
  --from-literal=password=<redis-password>

# NATS credentials
kubectl create secret generic nats-credentials \
  --from-literal=user=tazama \
  --from-literal=password=<nats-password>
```

### Step 2: Create values File

Create a `values-production.yaml` file with your configuration:

```yaml
# Example: External PostgreSQL + NATS, Internal Valkey
infrastructure:
  postgres:
    enabled: false
    external:
      enabled: true
      host: mydb.xxxx.rds.amazonaws.com
      port: 5432
      database: tazama
      secretRef:
        name: rds-credentials
      ssl:
        enabled: true
        skipVerify: false

  valkey:
    enabled: true  # Use internal

  nats:
    enabled: false
    external:
      enabled: true
      cluster:
        enabled: true
        urls:
          - "nats://nats-1.region.cloud.nats.io:4222"
          - "nats://nats-2.region.cloud.nats.io:4222"
          - "nats://nats-3.region.cloud.nats.io:4222"
      secretRef:
        name: nats-credentials
```

### Step 3: Install the Chart

```bash
# Dry-run to validate configuration
helm install tazama ./tazama-helm-derived \
  -n tazama --create-namespace \
  -f values-production.yaml \
  --dry-run --debug

# Install
helm install tazama ./tazama-helm-derived \
  -n tazama --create-namespace \
  -f values-production.yaml
```

### Step 4: Verify Installation

```bash
# Check pods
kubectl get pods -n tazama

# Check config map
kubectl get configmap tazama-core-config -n tazama -o yaml

# Verify NATS JetStream (internal mode)
kubectl logs -n tazama statefulset/nats | grep -i jetstream

# Or for external NATS, verify connection
kubectl logs -n tazama deployment/tms | grep -i nats
```

---

## Configuration Reference

### Global Settings

| Parameter | Default | Description |
|-----------|---------|-------------|
| `global.storageClass` | `""` | Storage class for PVCs |
| `global.imagePullSecrets` | `[]` | Image pull secrets |
| `validation.enabled` | `true` | Enable pre-install validation |
| `validationWarningsSuppressed` | `false` | Suppress info-level warnings |

### Infrastructure Configuration

Each infrastructure component follows this pattern:

```yaml
infrastructure:
  <component>:
    enabled: true              # Internal deployment
    image: "<component>:tag"   # Image for internal deployment
    resources:                 # Resource limits
      requests:
        cpu: "100m"
        memory: "256Mi"
      limits:
        cpu: "500m"
        memory: "512Mi"
    
    # External configuration (mutually exclusive with enabled=true)
    external:
      enabled: false           # Set true for external
      host: ""                 # External host
      port: <default_port>    # External port
      secretRef:
        name: ""               # Secret reference
        keys:
          user: "user"
          password: "password"
      ssl:
        enabled: true
        skipVerify: false      # WARNING: Dev only
```

---

## Examples

### Example 1: All Internal (Default)

```bash
helm install tazama ./tazama-helm-derived
```

Result:
- PostgreSQL StatefulSet with PVC
- Valkey Deployment
- NATS StatefulSet with JetStream persistence
- Services: `postgres:5432`, `valkey:6379`, `nats:4222`

---

### Example 2: External PostgreSQL (AWS RDS)

```bash
kubectl create secret generic rds-credentials \
  --from-literal=user=tazama \
  --from-literal=password=mysecurepassword123

helm install tazama ./tazama-helm-derived \
  --set infrastructure.postgres.enabled=false \
  --set infrastructure.postgres.external.enabled=true \
  --set infrastructure.postgres.external.host=mydb.xxxx.rds.amazonaws.com \
  --set infrastructure.postgres.external.secretRef.name=rds-credentials
```

---

### Example 3: External NATS Cluster (Cloud NATS)

```bash
kubectl create secret generic nats-creds \
  --from-literal=user=tazama_user \
  --from-literal=password=myNatsPassword

helm install tazama ./tazama-helm-derived \
  --set infrastructure.nats.enabled=false \
  --set infrastructure.nats.external.enabled=true \
  --set infrastructure.nats.external.cluster.enabled=true \
  --set "infrastructure.nats.external.cluster.urls[0]=nats://nats-1.xxxx.nats.io:4222" \
  --set "infrastructure.nats.external.cluster.urls[1]=nats://nats-2.xxxx.nats.io:4222" \
  --set "infrastructure.nats.external.cluster.urls[2]=nats://nats-3.xxxx.nats.io:4222" \
  --set infrastructure.nats.external.secretRef.name=nats-creds
```

---

### Example 4: Hybrid - External DB + Internal Cache + NATS

```yaml
# values-hybrid.yaml
infrastructure:
  postgres:
    enabled: false
    external:
      enabled: true
      host: prod-db.cluster-xxx.rds.amazonaws.com
      secretRef:
        name: prod-rds-secret

  valkey:
    enabled: true
    resources:
      limits:
        memory: "1Gi"

  nats:
    enabled: true
    jetStream:
      enabled: true
      storageSize: "10Gi"
      maxStore: "5Gi"
```

```bash
helm install tazama ./tazama-helm-derived -f values-hybrid.yaml
```

---

### Example 5: NATS Core Mode (No Persistence)

For development/testing where message persistence is not required:

```yaml
infrastructure:
  nats:
    enabled: true
    jetStream:
      enabled: false  # NATS Core only
```

**Note**: NATS Core mode does NOT persist messages. Use JetStream for production.

---

## Troubleshooting

### Common Errors

#### Error: mutually exclusive

```
Error: UPGRADE FAILED: NATS configuration error (C2): 'enabled' and 'external.enabled' are mutually exclusive
```

**Fix**: Set only ONE of `enabled` OR `external.enabled` to `true`, not both:

```yaml
infrastructure:
  nats:
    enabled: false          # <-- Must be false
    external:
      enabled: true         # <-- Only this is true
```

---

#### Error: required when external.enabled=true

```
Error: NATS external configuration error (C10): 'external.host' or 'external.cluster.urls' is required
```

**Fix**: Provide host OR cluster URLs:

```yaml
# Single host
infrastructure:
  nats:
    external:
      enabled: true
      host: "nats.example.com"

# OR cluster
infrastructure:
  nats:
    external:
      enabled: true
      cluster:
        enabled: true
        urls:
          - "nats://nats-1.example.com:4222"
          - "nats://nats-2.example.com:4222"
```

---

#### Error: secretRef.name is required

```
Error: NATS external configuration error (C10): 'external.secretRef.name' is required
```

**Fix**: Create a secret and reference it:

```bash
kubectl create secret generic nats-creds \
  --from-literal=user=tazama \
  --from-literal=password=securepassword
```

```yaml
infrastructure:
  nats:
    external:
      secretRef:
        name: nats-creds
```

---

### Verification Commands

```bash
# Check ConfigMap endpoints
kubectl get configmap tazama-core-config -o yaml | grep -E "(HOST|PORT|URL)"

# Verify NATS JetStream persistence
kubectl exec -it statefulset/nats -- nats server info | grep -i jetstream

# Check PVC for JetStream
kubectl get pvc nats-jetstream-pvc

# Test PostgreSQL connectivity
kubectl run pg-test --rm -it --image=postgres:18 -- \
  psql "postgres://user:pass@postgres:5432/tazama"

# Test NATS connectivity
kubectl run nats-test --rm -it --image=nats:2 -- \
  nats server info -s nats://nats:4222
```

---

## Upgrading

### From Internal to External

```bash
# 1. Export current data (if needed)
kubectl exec statefulset/postgres -- pg_dumpall > backup.sql

# 2. Delete release
helm uninstall tazama -n tazama

# 3. Create external credentials secret
kubectl create secret generic rds-credentials \
  --from-literal=user=admin \
  --from-literal=password=securepassword

# 4. Install with external config
helm install tazama ./tazama-helm-derived \
  --set infrastructure.postgres.enabled=false \
  --set infrastructure.postgres.external.enabled=true \
  --set infrastructure.postgres.external.host=mydb.rds.amazonaws.com \
  --set infrastructure.postgres.external.secretRef.name=rds-credentials

# 5. Import data (if needed)
# ... restore to external database
```

---

## Notes

### Security Considerations

1. **TLS is enabled by default** for all external connections
2. **Never** set `ssl.skipVerify=true` in production
3. Store all credentials in Kubernetes Secrets, never in values.yaml
4. Review warnings during `helm install` - they indicate security risks

### NATS JetStream vs Core

| Feature | JetStream (enabled=true) | Core (enabled=false) |
|---------|--------------------------|----------------------|
| Message Persistence | ✅ PVC-backed | ❌ Memory only |
| Replay | ✅ Supported | ❌ Not available |
| Durability | ✅ Survives restarts | ❌ Lost on restart |
| Guarantees | ✅ At-least-once | ❌ Best-effort |
| Production | ✅ Recommended | ❌ Dev-only |

---

## License

[License information here]
