#!/usr/bin/env python3
import re

with open('templates/_helpers.tpl', 'r', encoding='utf-8') as f:
    content = f.read()

# Find the old nats.url helper and replace with new one that handles cluster mode
old_helper = '''{{- define "tazama.nats.url" -}}
{{- $mode := include "tazama.infrastructure.mode" (dict "component" "nats" "context" .) -}}
{{- $infra := .Values.infrastructure.nats -}}

{{- if eq $mode "internal" -}}
  {{- printf "nats:4222" -}}
{{- else if eq $mode "external" -}}
  {{- printf "%s:%d" $infra.external.host (int $infra.external.port) -}}
{{- else -}}
  {{- "" -}}
{{- end }}
{{- end }}'''

new_helper = '''{{- define "tazama.nats.url" -}}
{{- $mode := include "tazama.infrastructure.mode" (dict "component" "nats" "context" .) -}}
{{- $infra := .Values.infrastructure.nats -}}

{{- if eq $mode "internal" -}}
  {{- /* Internal NATS - uses Kubernetes DNS service discovery */ -}}
  {{- printf "nats:4222" -}}
{{- else if eq $mode "external" -}}
  {{- if $infra.external.cluster.enabled -}}
    {{- /* External NATS cluster - return comma-separated URLs */ -}}
    {{- $urls := $infra.external.cluster.urls | join "," -}}
    {{- printf "%s" $urls -}}
  {{- else -}}
    {{- /* External single NATS endpoint */ -}}
    {{- printf "%s:%d" $infra.external.host (int $infra.external.port) -}}
  {{- end -}}
{{- else -}}
  {{- /* Disabled - return empty */ -}}
  {{- printf "" -}}
{{- end -}}
{{- end -}}

{{- /*
  tazama.nats.hosts - Returns array of NATS server hosts for cluster configs
  Usage: {{ include "tazama.nats.hosts" $ }}
*/ -}}
{{- define "tazama.nats.hosts" -}}
{{- $mode := include "tazama.infrastructure.mode" (dict "component" "nats" "context" .) -}}
{{- $infra := .Values.infrastructure.nats -}}

{{- if eq $mode "internal" -}}
  {{- list "nats:4222" | toJson -}}
{{- else if eq $mode "external" -}}
  {{- if $infra.external.cluster.enabled -}}
    {{- $infra.external.cluster.urls | toJson -}}
  {{- else -}}
    {{- list (printf "%s:%d" $infra.external.host (int $infra.external.port)) | toJson -}}
  {{- end -}}
{{- else -}}
  {{- list "" | toJson -}}
{{- end -}}
{{- end -}}'''

# Replace
if old_helper in content:
    content = content.replace(old_helper, new_helper)
    print("Replaced old helper with new cluster-aware helper")
else:
    print("Old helper not found")
    print("\nSearching for current state...")
    pattern = r'{{- define "tazama\.nats\.url" -}}.*?{{- end ?}}'
    match = re.search(pattern, content, flags=re.DOTALL)
    if match:
        print(f"Found helper at position {match.start()}")
        print(f"Content: {match.group(0)[:200]}...")

with open('templates/_helpers.tpl', 'w', encoding='utf-8') as f:
    f.write(content)
