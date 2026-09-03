#!/usr/bin/env python3
import re

with open('templates/_validation.tpl', 'r', encoding='utf-8') as f:
    content = f.read()

new_validation = '''{{- define "tazama.validation.nats" -}}
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

{{- end -}}'''

pattern = r'({{- define "tazama\.validation\.nats" -}}\s*{{- \$infra := \.Values\.infrastructure\.nats -}}.*?{{- end -}})'
match = re.search(pattern, content, flags=re.DOTALL)

if match:
    content = re.sub(pattern, new_validation, content, flags=re.DOTALL)
    with open('templates/_validation.tpl', 'w', encoding='utf-8') as f:
        f.write(content)
    print('NATS validation updated with cluster and JetStream checks')
else:
    print('ERROR: Could not find NATS validation section to replace')
