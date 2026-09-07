# Configuration Seed Feature

This directory contains templates for seeding the Tazama configuration database with default NetworkMap, RuleConfig, and TypologyConfig documents.

## Files

| File | Purpose |
|------|---------|
| `config-seed-job.yaml` | Kubernetes Job that seeds the configuration database on first deploy |
| `example-configurations.yaml` | Sample configuration documents for reference |
| `values-fragment.yaml` | Values.yaml fragment with configSeed configuration |

## How It Works

1. **Enable Configuration Seeding** in `values.yaml`:

```yaml
configSeed:
  enabled: true
  version: "v1"
  tenantId: "default"
```

2. **Deploy the Chart**:

```bash
helm upgrade --install tazama ./tazama-helm-derived \
  --set configSeed.enabled=true
```

3. **Configuration is Seeded** automatically via a post-install hook:
   - Checks if configuration already exists (idempotent)
   - Inserts NetworkMap, RuleConfigs, and TypologyConfigs
   - Skips if already seeded (same cfg + tenantId)

## NetworkMap Structure

```json
{
  "active": true,
  "cfg": "default-v1",
  "tenantId": "default",
  "messages": [
    {
      "id": "pain.001.001.11",
      "cfg": "pain001-default-v1",
      "txTp": "pacs.008",
      "typologies": [
        {
          "id": "typology-01",
          "cfg": "typology-01-v1",
          "rules": [
            { "id": "rule-901", "cfg": "rule-901-v1" },
            { "id": "rule-902", "cfg": "rule-902-v1" }
          ]
        }
      ]
    }
  ]
}
```

## RuleConfig Structure

```json
{
  "id": "rule-901",
  "cfg": "rule-901-v1",
  "tenantId": "default",
  "config": {
    "parameters": { ... },
    "bands": [ ... ],
    "exitConditions": [ ... ]
  }
}
```

## TypologyConfig Structure

```json
{
  "id": "typology-01",
  "cfg": "typology-01-v1",
  "tenantId": "default",
  "config": {
    "expression": "({rule-901} * 0.6) + ({rule-902} * 0.4)",
    "threshold": 50,
    "bands": [ ... ]
  }
}
```

## Adding Custom Rules

To add custom rules beyond the default set:

```yaml
rules:
  additional:
    - rule-903
    - rule-904
```

Then add the corresponding RuleConfig entries to configSeed.ruleConfigs.

## Updating Configuration

To update configuration after deployment:

1. Increment the `configSeed.version` (e.g., `v1` → `v2`)
2. Run `helm upgrade`
3. New configuration is seeded as a new version

Alternatively, use the Tazama API to update configuration directly.

## Troubleshooting

**Job fails with "connection refused":**
- Ensure PostgreSQL is running: `kubectl get pods -l app=postgres`
- Check database credentials in secret: `kubectl get secret tazama-shared-secrets -o yaml`

**Configuration not taking effect:**
- Verify NetworkMap is active: `SELECT * FROM networkmap WHERE active = true;`
- Check rule results in event_history database

**Job hangs:**
- Check init container logs: `kubectl logs job/tazama-config-seed -c wait-for-postgres`
- Increase timeout: `helm upgrade ... --set configSeed.timeout=600`
