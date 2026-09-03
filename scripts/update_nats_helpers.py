#!/usr/bin/env python3
"""Update NATS helpers in _helpers.tpl"""

import re

with open('templates/_helpers.tpl', 'r', encoding='utf-8') as f:
    content = f.read()

# Check if tazama.nats.hosts already exists
if 'tazama.nats.hosts' in content:
    print('NATS helpers already up to date')
else:
    # Find the end of the existing nats.url helper
    pattern = r'({{- define "tazama\.nats\.url" -}}.*?{{- end -}})'
    
    replacement = r'''\1

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
  {{- list "nats:4222" | toJson -}}
{{- end -}}
{{- end -}}'''
    
    content = re.sub(pattern, replacement, content, flags=re.DOTALL)
    
    with open('templates/_helpers.tpl', 'w', encoding='utf-8') as f:
        f.write(content)
    print('NATS hosts helper appended')
