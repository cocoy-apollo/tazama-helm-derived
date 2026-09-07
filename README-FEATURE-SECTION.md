---

## Feature Branch: Configuration Seeding (`feature/all-rules-config`)

This branch extends the base Helm chart with **automatic configuration seeding** for typologies, rules, and network maps. On first deployment, a Kubernetes Job populates the database with the required configuration documents.

### What This Branch Adds

| File | Purpose |
|------|---------|
| `templates/config/config-seed-job.yaml` | Kubernetes Job that seeds NetworkMap, RuleConfig, TypologyConfig |
| `templates/config/example-configurations.yaml` | Sample configuration documents |
| `templates/config/values-fragment.yaml` | values.yaml snippet for enabling config seeding |
| `templates/config/README.md` | Detailed documentation for config-seed feature |
| `templates/rules/rules.yaml` | Enhanced with parameterized rule deployment and resource limits |

### Quick Start

**1. Enable configuration seeding in your `values.yaml`:**

```yaml
configSeed:
  enabled: true  # Set to true to enable automatic seeding
  version: "v1"
  tenantId: "default"

  # NetworkMap: wires message types to typologies and rules
  networkMap:
    cfg:
      id: "network-map-001"
      typology:
        typology:
          - id: "typology-01"
            name: "Transaction Monitoring"
            rules:
              - rule:
                  id: "rule-901"
                  name: "Amount Threshold"
                  url: "rule-901-rel-1-0-0"
              - rule:
                  id: "rule-902"
                  name: "Frequency Threshold"
                  url: "rule-902-rel-1-0-0"

  # RuleConfig: parameters for each rule
  ruleConfigs:
    - cfg:
        id: "rule-901-config"
        ruleId: "901"
        bands:
          - lower: 0
            upper: 1000
            score: 1
          - lower: 1000
            upper: 10000
            score: 2
          - lower: 10000
            upper: 100000
            score: 3
      tenantId: "default"

  # TypologyConfig: scoring formulas
  typologyConfigs:
    - cfg:
        id: "typology-01-config"
        typologyId: "01"
        formula: "sum(ruleScores) / count(rules)"
        threshold: 50
      tenantId: "default"
```

**2. Deploy with config seeding enabled:**

```bash
helm upgrade --install tazama ./tazama-helm-derived \
  -n tazama --create-namespace \
  -f values.yaml \
  --set configSeed.enabled=true
```

**3. Verify configuration was seeded:**

```bash
# Check the config-seed job completed successfully
kubectl get jobs -n tazama

# View job logs
kubectl logs job/tazama-config-seed -n tazama

# Verify configuration in database
kubectl exec -it statefulset/postgres -n tazama -- \
  psql -U tazama -d configuration -c "SELECT * FROM networkmap;"
```

### Components

#### NetworkMap

The NetworkMap defines the routing between incoming messages, typologies, and rules:

```
Message Type → Typology → Rules
     ↓
pacs.008 → typology-01 → [rule-901, rule-902]
```

When a `pacs.008` message arrives:
1. TMS routes it to `typology-01`
2. Typology invokes `rule-901` and `rule-902`
3. Each rule returns a score
4. Typology aggregates scores using its formula
5. Result is sent downstream

#### RuleConfig

Each rule has configuration that defines its behavior:

| Field | Description |
|-------|-------------|
| `bands` | Score ranges based on thresholds (e.g., transaction amount) |
| `url` | NATS subject the rule subscribes to |
| `decisions` | Business logic revisions |
| `params` | Additional parameters |

#### TypologyConfig

Typology configuration defines how rule results are combined:

| Field | Description |
|-------|-------------|
| `formula` | Aggregation function (sum, average, weighted) |
| `threshold` | Alert threshold score |
| `weights` | Per-rule weights for weighted formulas |

### Adding Additional Rules

To add more rules beyond the default `rule-901` and `rule-902`:

**Option 1: Via values.yaml**

```yaml
rules:
  additional:
    - rule-903
    - rule-904
    - rule-905
```

**Option 2: Via command line**

```bash
helm upgrade --install tazama ./tazama-helm-derived \
  --set "rules.additional[0]=rule-903" \
  --set "rules.additional[1]=rule-904"
```

### Deployment Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Kubernetes Cluster                       │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐  │
│  │    TMS       │───▶│     NATS     │───▶│  Typology    │  │
│  │ (Transaction │    │ (Message     │    │  Processor   │  │
│  │  Monitor)    │    │  Broker)     │    │              │  │
│  └──────────────┘    └──────────────┘    └──────┬───────┘  │
│                                                  │          │
│                              ┌──────────────────┼───────┐  │
│                              │                  │       │  │
│                              ▼                  ▼       ▼  │
│                        ┌──────────┐      ┌──────────┐     │
│                        │ Rule-901 │      │ Rule-902 │ ... │
│                        │ (Amt)    │      │ (Count)  │     │
│                        └──────────┘      └──────────┘     │
│                              │                  │          │
│                              └────────┬─────────┘          │
│                                       ▼                    │
│                              ┌──────────────┐              │
│                              │  PostgreSQL  │              │
│                              │ (Config DB)  │              │
│                              │              │              │
│                              │ • networkmap │              │
│                              │ • ruleconfig │              │
│                              │ • typology   │              │
│                              └──────────────┘              │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Config-Seed Job Behavior

1. **Init Container**: Waits for PostgreSQL to be ready
2. **Main Container**: Connects to `configuration` database
3. **Idempotent**: Checks if config already exists before inserting
4. **Unique Key**: Uses `cfg.id` + `tenantId` as unique identifier
5. **Logging**: Outputs detailed progress to stdout

**Job output example:**

```
Waiting for PostgreSQL...
PostgreSQL is ready!
Seeding NetworkMap...
  → Inserted: network-map-001
Seeding RuleConfig...
  → Inserted: rule-901-config
  → Inserted: rule-902-config
Seeding TypologyConfig...
  → Inserted: typology-01-config
Configuration seeding complete!
```

### Troubleshooting Config Seeding

#### Job fails to connect to database

```bash
# Check PostgreSQL is running
kubectl get pods -n tazama -l app=postgres

# Check database credentials
kubectl get secret postgres-credentials -n tazama -o yaml

# Check job logs
kubectl logs job/tazama-config-seed -n tazama
```

#### Configuration already exists error

This is expected if the job runs multiple times. The config-seed job is idempotent — it skips documents that already exist.

#### Missing configuration after deployment

```bash
# Verify job completed
kubectl get jobs -n tazama

# Check if documents exist
kubectl exec -it statefulset/postgres -n tazama -- \
  psql -U tazama -d configuration -c "SELECT cfg->>'id' FROM networkmap;"
```

### Merging This Branch to Master

Once validated, merge to master:

```bash
git checkout master
git merge feature/all-rules-config
git push origin master
```

Or create a pull request on GitHub for code review.

---

## Available Rules (tazama-lf)

| Rule ID | Name | Purpose | Container Image |
|---------|------|---------|-----------------|
| `rule-901` | Amount Threshold | Monitors transaction amounts against bands | `ghcr.io/tazama-lf/rule-901` |
| `rule-902` | Frequency Counter | Monitors transaction count per time window | `ghcr.io/tazama-lf/rule-902` |

Additional rules may be available in the [tazama-lf repository](https://github.com/tazama-lf). Check for `rule-*` repositories.

---

## Security Notes for Config Seeding

1. **Database credentials** are read from the same Secret used by other components
2. **No secrets in values.yaml** — all credentials come from Kubernetes Secrets
3. **Job runs once** — the Job completes after seeding and doesn't persist
4. **NetworkMap contains business logic** — treat as sensitive configuration
5. **Tenant isolation** — each tenant's configuration is isolated by `tenantId`
