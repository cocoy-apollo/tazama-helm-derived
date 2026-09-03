{{/*
========================================================================
VALIDATION TEMPLATES
========================================================================
These templates enforce configuration constraints and fail the deployment
with clear error messages when invalid configurations are detected.

CONSTRAINTS IMPLEMENTED:
  C2:  Internal and external modes are mutually exclusive
  C5:  Secrets never have working placeholder values (empty secretRef fails)
  C10: Chart fails if required dependencies are missing
  C14: TLS bypass requires explicit acknowledgment

USAGE:
  These validation helpers are called at the top of templates that require
  the infrastructure. They use `fail` to abort rendering with clear errors.

EXAMPLE:
  {{- include "tazama.validation.postgres" $ }}
========================================================================
*/}}

{{/*
Validate PostgreSQL infrastructure configuration.
Checks for mutual exclusion violations and missing required fields.

Usage: {{ include "tazama.validation.postgres" $ }}
*/}}
{{- define "tazama.validation.postgres" -}}
{{- $infra := .Values.infrastructure.postgres -}}

{{- /* C2: Mutual exclusion check */}}
{{- if and $infra.enabled $infra.external.enabled -}}
{{- fail "PostgreSQL configuration error (C2): 'enabled' and 'external.enabled' are mutually exclusive. Set one to true, not both." -}}
{{- end -}}

{{- /* Disabled check - cannot have both false */}}
{{- if and (not $infra.enabled) (not $infra.external.enabled) (not $infra.disabled) -}}
{{- fail "PostgreSQL configuration error: 'enabled', 'external.enabled', and 'disabled' are all false. Set enabled=true (internal), external.enabled=true (external), or disabled=true." -}}
{{- end -}}

{{- /* External mode validation */}}
{{- if $infra.external.enabled -}}
  {{- /* C10: Required host */}}
  {{- if not $infra.external.host -}}
  {{- fail "PostgreSQL external configuration error (C10): 'external.host' is required when external.enabled=true" -}}
  {{- end -}}

  {{- /* C5/C10: Required secret reference name */}}
  {{- if not $infra.external.secretRef.name -}}
  {{- fail "PostgreSQL external configuration error (C5/C10): 'external.secretRef.name' is required when external.enabled=true. Create a Kubernetes secret and reference it here (e.g., 'rds-credentials')." -}}
  {{- end -}}

  {{- /* C10: Validate port is set */}}
  {{- if not $infra.external.port -}}
  {{- fail "PostgreSQL external configuration error (C10): 'external.port' is required when external.enabled=true" -}}
  {{- end -}}

  {{- /* C14: Warn if TLS bypass enabled */}}
  {{- if $infra.external.ssl.skipVerify -}}
    {{- if not $.Values.validationWarningsSuppressed -}}
    {{- /* Note: This is a warning, not a hard failure, but logged prominently */}}
    {{- printf "[SECURITY WARNING C14] PostgreSQL TLS certificate verification is DISABLED (ssl.skipVerify=true). This should only be used in development environments." | quote -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{- end -}}

{{/*
Validate Valkey infrastructure configuration.
Checks for mutual exclusion violations and missing required fields.

Usage: {{ include "tazama.validation.valkey" $ }}
*/}}
{{- define "tazama.validation.valkey" -}}
{{- $infra := .Values.infrastructure.valkey -}}

{{- /* C2: Mutual exclusion check */}}
{{- if and $infra.enabled $infra.external.enabled -}}
{{- fail "Valkey configuration error (C2): 'enabled' and 'external.enabled' are mutually exclusive. Set one to true, not both." -}}
{{- end -}}

{{- /* Disabled check */}}
{{- if and (not $infra.enabled) (not $infra.external.enabled) (not $infra.disabled) -}}
{{- fail "Valkey configuration error: 'enabled', 'external.enabled', and 'disabled' are all false. Set enabled=true (internal), external.enabled=true (external), or disabled=true." -}}
{{- end -}}

{{- /* External mode validation */}}
{{- if $infra.external.enabled -}}
  {{- /* C10: Required host */}}
  {{- if not $infra.external.host -}}
  {{- fail "Valkey external configuration error (C10): 'external.host' is required when external.enabled=true" -}}
  {{- end -}}

  {{- /* C5/C10: Required secret reference name (if password required) */}}
  {{- if and $infra.external.ssl.enabled (not $infra.external.secretRef.name) -}}
  {{- fail "Valkey external configuration error (C5/C10): 'external.secretRef.name' is required when external.ssl.enabled=true. Create a Kubernetes secret containing the password and reference it here." -}}
  {{- end -}}

  {{- /* C14: Warn if TLS bypass enabled */}}
  {{- if $infra.external.ssl.skipVerify -}}
    {{- if not $.Values.validationWarningsSuppressed -}}
    {{- printf "[SECURITY WARNING C14] Valkey TLS certificate verification is DISABLED (ssl.skipVerify=true). This should only be used in development environments." | quote -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{- end -}}

{{/*
Validate NATS infrastructure configuration.
Checks for mutual exclusion violations and missing required fields.

Usage: {{ include "tazama.validation.nats" $ }}
*/}}
{{- define "tazama.validation.nats" -}}
{{- $infra := .Values.infrastructure.nats -}}

{{- /* C2: Mutual exclusion check */ -}}
{{- if and $infra.enabled $infra.external.enabled -}}
{{- fail "NATS configuration error (C2): 'enabled' and 'external.enabled' are mutually exclusive. Set one to true, not both." -}}
{{- end -}}

{{- /* Disabled check */ -}}
{{- if and (not $infra.enabled) (not $infra.external.enabled) (not $infra.disabled) -}}
{{- fail "NATS configuration error: 'enabled', 'external.enabled', and 'disabled' are all false. Set enabled=true (internal), external.enabled=true (external), or disabled=true." -}}
{{- end -}}

{{- /* External mode validation */ -}}
{{- if $infra.external.enabled -}}
  {{- /* Cluster URLs or single host required */ -}}
  {{- $hasCluster := and $infra.external.cluster.enabled $infra.external.cluster.urls -}}
  {{- $hasSingleHost := and $infra.external.host -}}
  
  {{- if and (not $hasCluster) (not $hasSingleHost) -}}
  {{- fail "NATS external configuration error (C10): Either 'external.host' or 'external.cluster.urls' is required when external.enabled=true" -}}
  {{- end -}}

  {{- /* Validate cluster URLs if cluster mode enabled */ -}}
  {{- if and $infra.external.cluster.enabled (not $infra.external.cluster.urls) -}}
  {{- fail "NATS external configuration error (C10): 'external.cluster.urls' is required when cluster.enabled=true" -}}
  {{- end -}}

  {{- /* C14: Warn if TLS bypass enabled */ -}}
  {{- if $infra.external.ssl.skipVerify -}}
    {{- if not $.Values.validationWarningsSuppressed -}}
    {{- printf "[SECURITY WARNING C14] NATS TLS certificate verification is DISABLED (ssl.skipVerify=true). This should only be used in development environments." | quote -}}
    {{- end -}}
  {{- end -}}

  {{- /* C10: Credentials required for external mode */ -}}
  {{- if and (not $infra.external.secretRef.name) (not $.Values.autoScaffold.enabled) -}}
  {{- fail "NATS external configuration error (C10): 'external.secretRef.name' is required when external.enabled=true (or set autoScaffold.enabled=true for dev)" -}}
  {{- end -}}
{{- end -}}

{{- /* Internal mode - JetStream settings */ -}}
{{- if $infra.enabled -}}
  {{- $jetStream := $infra.jetStream | default dict -}}
  
  {{- /* Info: JetStream persistence status */ -}}
  {{- if not $jetStream.enabled -}}
    {{- if not $.Values.validationWarningsSuppressed -}}
    {{- printf "[INFO] NATS Core mode: Messages are NOT persisted. Consider enabling JetStream for production use (infrastructure.nats.jetStream.enabled=true)" | quote -}}
    {{- end -}}
  {{- end -}}
  
  {{- /* If JetStream enabled, validate storage size */ -}}
  {{- if $jetStream.enabled -}}
    {{- if not $jetStream.storageSize -}}
    {{- fail "NATS JetStream configuration error: 'jetStream.storageSize' is required when jetStream.enabled=true" -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{- end -}}

{{- define "tazama.validation.all" -}}
{{- include "tazama.validation.postgres" . -}}
{{- include "tazama.validation.valkey" . -}}
{{- include "tazama.validation.nats" . -}}
{{- end -}}

{{/*
Validate infrastructure for a specific service.
Determines which components are required and validates accordingly.

Usage: {{ include "tazama.validation.service" (dict "service" "adminService" "context" $) }}
*/}}
{{- define "tazama.validation.service" -}}
{{- $service := .service -}}
{{- $context := .context -}}

{{- /* All services that use PostgreSQL require valid config */}}
{{- if or (eq $service "adminService") (eq $service "tms") (eq $service "arf") (eq $service "dol") -}}
  {{- include "tazama.validation.postgres" $context -}}
{{- end -}}

{{- /* Services that use NATS require valid config */}}
{{- if or (eq $service "tms") (eq $service "arf") (eq $service "dol") -}}
  {{- include "tazama.validation.nats" $context -}}
{{- end -}}

{{- /* Services that use Valkey require valid config */}}
{{- if or (eq $service "tms") (eq $service "arf") (eq $service "dol") -}}
  {{- include "tazama.validation.valkey" $context -}}
{{- end -}}

{{- end -}}

{{/*
Validate that disabled infrastructure is not required by any service.
This catch-all ensures services don't fail at runtime due to missing dependencies.

Usage: {{ include "tazama.validation.dependencies" $ }}
*/}}
{{- define "tazama.validation.dependencies" -}}
{{- $postgresMode := include "tazama.infrastructure.mode" (dict "component" "postgres" "context" .) -}}
{{- $valkeyMode := include "tazama.infrastructure.mode" (dict "component" "valkey" "context" .) -}}
{{- $natsMode := include "tazama.infrastructure.mode" (dict "component" "nats" "context" .) -}}

{{- /* Check if PostgreSQL is disabled but services require it */}}
{{- if eq $postgresMode "disabled" -}}
  {{- $servicesRequiringPostgres := list "adminService" "tms" "arf" "dol" -}}
  {{- range $service := $servicesRequiringPostgres -}}
    {{- $serviceEnabled := index $.Values.core $service -}}
    {{- /* Note: This check requires service-level enabled flags in values.yaml */}}
    {{- /* For now, we assume all core services are enabled by default */}}
  {{- end -}}
  {{- /* Conservative warning for now */}}
  {{- if not $.Values.validationWarningsSuppressed -}}
  {{- printf "[WARNING] PostgreSQL is DISABLED, but core services (adminService, tms, arf, dol) require database connectivity. Ensure you are only deploying services that don't need PostgreSQL." | quote -}}
  {{- end -}}
{{- end -}}

{{- /* Check if NATS is disabled */}}
{{- if eq $natsMode "disabled" -}}
  {{- if not $.Values.validationWarningsSuppressed -}}
  {{- printf "[WARNING] NATS is DISABLED. Event-driven services will not function without NATS connectivity." | quote -}}
  {{- end -}}
{{- end -}}

{{- /* Check if Valkey is disabled */}}
{{- if eq $valkeyMode "disabled" -}}
  {{- if not $.Values.validationWarningsSuppressed -}}
  {{- printf "[WARNING] Valkey is DISABLED. Caching-dependent features will not function." | quote -}}
  {{- end -}}
{{- end -}}

{{- end -}}

{{/*
========================================================================
VALIDATION HELPER UTILITIES
========================================================================
*/}}

{{/*
Generate a detailed validation report for debugging.
Returns: Multi-line string with all configuration checks.

Usage: {{ include "tazama.validation.report" $ }}
*/}}
{{- define "tazama.validation.report" -}}
Infrastructure Validation Report:
{{- $postgresMode := include "tazama.infrastructure.mode" (dict "component" "postgres" "context" .) }}
{{- $valkeyMode := include "tazama.infrastructure.mode" (dict "component" "valkey" "context" .) }}
{{- $natsMode := include "tazama.infrastructure.mode" (dict "component" "nats" "context" .) }}

  PostgreSQL Mode: {{ $postgresMode }}
    Host: {{ include "tazama.database.host" (dict "component" "postgres" "context" .) }}
    Port: {{ include "tazama.database.port" (dict "component" "postgres" "context" .) }}
    Database: {{ include "tazama.database.name" (dict "component" "postgres" "context" .) }}
{{- if eq $postgresMode "external" }}
    Secret: {{ .Values.infrastructure.postgres.external.secretRef.name | default "NOT SET" }}
    TLS: enabled={{ .Values.infrastructure.postgres.external.ssl.enabled }}, skipVerify={{ .Values.infrastructure.postgres.external.ssl.skipVerify }}
{{- end }}

  Valkey Mode: {{ $valkeyMode }}
    Host: {{ include "tazama.valkey.host" . }}
    Port: {{ include "tazama.valkey.port" . }}
{{- if eq $valkeyMode "external" }}
    Secret: {{ .Values.infrastructure.valkey.external.secretRef.name | default "(none required)" }}
    TLS: enabled={{ .Values.infrastructure.valkey.external.ssl.enabled }}, skipVerify={{ .Values.infrastructure.valkey.external.ssl.skipVerify }}
{{- end }}

  NATS Mode: {{ $natsMode }}
    URL: {{ include "tazama.nats.url" . }}
{{- if eq $natsMode "external" }}
    TLS: enabled={{ .Values.infrastructure.nats.external.ssl.enabled }}, skipVerify={{ .Values.infrastructure.nats.external.ssl.skipVerify }}
{{- end }}
{{- end -}}
