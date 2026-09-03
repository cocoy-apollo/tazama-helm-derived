{{/*
Expand the name of the chart.
*/}}
{{- define "tazama.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "tazama.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "tazama.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "tazama.labels" -}}
helm.sh/chart: {{ include "tazama.chart" . }}
{{ include "tazama.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "tazama.selectorLabels" -}}
app.kubernetes.io/name: {{ include "tazama.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "tazama.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "tazama.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
========================================================================
INFRASTRUCTURE MODE DETECTION HELPERS
========================================================================
*/}}

{{/*
Determine the deployment mode for a given infrastructure component.
Returns: "internal", "external", or "disabled"

Usage: {{ include "tazama.infrastructure.mode" (dict "component" "postgres" "context" $) }}
*/}}
{{- define "tazama.infrastructure.mode" -}}
{{- $component := .component -}}
{{- $context := .context -}}
{{- $infra := index $context.Values.infrastructure $component -}}

{{- if $infra -}}
  {{- if $infra.external.enabled -}}
    {{- "external" -}}
  {{- else if $infra.enabled -}}
    {{- "internal" -}}
  {{- else -}}
    {{- "disabled" -}}
  {{- end }}
{{- else -}}
  {{- "disabled" -}}
{{- end }}
{{- end }}

{{/*
Check if internal infrastructure should be deployed for a component.
Returns: "true" or "" (falsy)

Usage: {{ include "tazama.infrastructure.internal.enabled" (dict "component" "postgres" "context" $) }}
*/}}
{{- define "tazama.infrastructure.internal.enabled" -}}
{{- $mode := include "tazama.infrastructure.mode" (dict "component" .component "context" .context) -}}
{{- if eq $mode "internal" -}}
  {{- "true" -}}
{{- end }}
{{- end }}

{{/*
Check if external infrastructure is configured for a component.
Returns: "true" or "" (falsy)

Usage: {{ include "tazama.infrastructure.external.enabled" (dict "component" "postgres" "context" $) }}
*/}}
{{- define "tazama.infrastructure.external.enabled" -}}
{{- $mode := include "tazama.infrastructure.mode" (dict "component" .component "context" .context) -}}
{{- if eq $mode "external" -}}
  {{- "true" -}}
{{- end }}
{{- end }}

{{/*
Check if infrastructure component is disabled (neither internal nor external).
Returns: "true" or "" (falsy)

Usage: {{ include "tazama.infrastructure.disabled" (dict "component" "nats" "context" $) }}
*/}}
{{- define "tazama.infrastructure.disabled" -}}
{{- $mode := include "tazama.infrastructure.mode" (dict "component" .component "context" .context) -}}
{{- if eq $mode "disabled" -}}
  {{- "true" -}}
{{- end }}
{{- end }}

{{/*
========================================================================
ENDPOINT RESOLUTION HELPERS
========================================================================
*/}}

{{/*
Get the hostname for a database component.
Returns: internal service name or external host

Usage: {{ include "tazama.database.host" (dict "component" "postgres" "context" $) }}
*/}}
{{- define "tazama.database.host" -}}
{{- $component := .component -}}
{{- $context := .context -}}
{{- $infra := index $context.Values.infrastructure $component -}}
{{- $mode := include "tazama.infrastructure.mode" (dict "component" $component "context" $context) -}}

{{- if eq $mode "internal" -}}
  {{- $component -}}
{{- else if eq $mode "external" -}}
  {{- $infra.external.host | default "" -}}
{{- else -}}
  {{- "" -}}
{{- end }}
{{- end }}

{{/*
Get the port for a database component.
Returns: internal default port or external port

Usage: {{ include "tazama.database.port" (dict "component" "postgres" "context" $) }}
*/}}
{{- define "tazama.database.port" -}}
{{- $component := .component -}}
{{- $context := .context -}}
{{- $infra := index $context.Values.infrastructure $component -}}
{{- $mode := include "tazama.infrastructure.mode" (dict "component" $component "context" $context) -}}

{{- if eq $mode "internal" -}}
  {{- if eq $component "postgres" -}}
    {{- 5432 -}}
  {{- else -}}
    {{- $infra.port | default 5432 -}}
  {{- end }}
{{- else if eq $mode "external" -}}
  {{- $infra.external.port | default 5432 -}}
{{- else -}}
  {{- 5432 -}}
{{- end }}
{{- end }}

{{/*
Get the database name for a database component.
Returns: database name from internal or external config

Usage: {{ include "tazama.database.name" (dict "component" "postgres" "context" $) }}
*/}}
{{- define "tazama.database.name" -}}
{{- $component := .component -}}
{{- $context := .context -}}
{{- $infra := index $context.Values.infrastructure $component -}}
{{- $mode := include "tazama.infrastructure.mode" (dict "component" $component "context" $context) -}}

{{- if eq $mode "internal" -}}
  {{- "tazama" -}}
{{- else if eq $mode "external" -}}
  {{- $infra.external.database | default "tazama" -}}
{{- else -}}
  {{- "tazama" -}}
{{- end }}
{{- end }}

{{/*
Get the NATS server URL.
Returns: NATS connection URL (host:port format)

Usage: {{ include "tazama.nats.url" $ }}
*/}}
{{- define "tazama.nats.url" -}}
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
{{- end -}}

{{/*
Get the Valkey/Redis host.
Returns: Valkey hostname

Usage: {{ include "tazama.valkey.host" $ }}
*/}}
{{- define "tazama.valkey.host" -}}
{{- $mode := include "tazama.infrastructure.mode" (dict "component" "valkey" "context" .) -}}
{{- $infra := .Values.infrastructure.valkey -}}

{{- if eq $mode "internal" -}}
  {{- "valkey" -}}
{{- else if eq $mode "external" -}}
  {{- $infra.external.host | default "" -}}
{{- else -}}
  {{- "" -}}
{{- end }}
{{- end }}

{{/*
Get the Valkey/Redis port.
Returns: Valkey port number

Usage: {{ include "tazama.valkey.port" $ }}
*/}}
{{- define "tazama.valkey.port" -}}
{{- $mode := include "tazama.infrastructure.mode" (dict "component" "valkey" "context" .) -}}
{{- $infra := .Values.infrastructure.valkey -}}

{{- if eq $mode "internal" -}}
  {{- 6379 -}}
{{- else if eq $mode "external" -}}
  {{- $infra.external.port | default 6379 -}}
{{- else -}}
  {{- 6379 -}}
{{- end }}
{{- end }}

{{/*
Get the Valkey/Redis server configuration JSON.
Returns: JSON array with host and port for REDIS_SERVERS env var

Usage: {{ include "tazama.valkey.serversJson" $ }}
*/}}
{{- define "tazama.valkey.serversJson" -}}
{{- $host := include "tazama.valkey.host" . -}}
{{- $port := include "tazama.valkey.port" . -}}
{{- printf "[{\"host\":\"%s\",\"port\":%d}]" $host (int $port) -}}
{{- end }}

{{/*
========================================================================
SECRET REFERENCE HELPERS
========================================================================
*/}}

{{/*
Get the secret name for database credentials.
Returns: internal secret name or external secret reference

Usage: {{ include "tazama.database.secretName" (dict "component" "postgres" "context" $) }}
*/}}
{{- define "tazama.database.secretName" -}}
{{- $component := .component -}}
{{- $context := .context -}}
{{- $mode := include "tazama.infrastructure.mode" (dict "component" $component "context" $context) -}}
{{- $infra := index $context.Values.infrastructure $component -}}

{{- if eq $mode "internal" -}}
  {{- printf "%s-%s-credentials" $context.Release.Name $component -}}
{{- else if eq $mode "external" -}}
  {{- $infra.external.secretRef.name | default "" -}}
{{- else -}}
  {{- "" -}}
{{- end }}
{{- end }}

{{/*
Get the password key name for database credentials.
Returns: Key within the secret for password

Usage: {{ include "tazama.database.passwordKey" (dict "component" "postgres" "context" $) }}
*/}}
{{- define "tazama.database.passwordKey" -}}
{{- $component := .component -}}
{{- $context := .context -}}
{{- $mode := include "tazama.infrastructure.mode" (dict "component" $component "context" $context) -}}
{{- $infra := index $context.Values.infrastructure $component -}}

{{- if eq $mode "internal" -}}
  {{- "password" -}}
{{- else if eq $mode "external" -}}
  {{- $infra.external.secretRef.keys.password | default "password" -}}
{{- else -}}
  {{- "password" -}}
{{- end }}
{{- end }}

{{/*
Get the username key name for database credentials.
Returns: Key within the secret for username

Usage: {{ include "tazama.database.usernameKey" (dict "component" "postgres" "context" $) }}
*/}}
{{- define "tazama.database.usernameKey" -}}
{{- $component := .component -}}
{{- $context := .context -}}
{{- $mode := include "tazama.infrastructure.mode" (dict "component" $component "context" $context) -}}
{{- $infra := index $context.Values.infrastructure $component -}}

{{- if eq $mode "internal" -}}
  {{- "username" -}}
{{- else if eq $mode "external" -}}
  {{- $infra.external.secretRef.keys.username | default "username" -}}
{{- else -}}
  {{- "username" -}}
{{- end }}
{{- end }}

{{/*
========================================================================
INITCONTAINER WAIT HELPERS
========================================================================
*/}}

{{/*
Determine if database wait initContainer should be rendered.
Returns: "true" or "" (falsy)

Usage: {{ include "tazama.initContainer.waitDb" $ }}
*/}}
{{- define "tazama.initContainer.waitDb" -}}
{{- $postgresMode := include "tazama.infrastructure.mode" (dict "component" "postgres" "context" .) -}}
{{- if or (eq $postgresMode "internal") (eq $postgresMode "external") -}}
  {{- "true" -}}
{{- end }}
{{- end }}

{{/*
Determine if Valkey wait initContainer should be rendered.
Returns: "true" or "" (falsy)

Usage: {{ include "tazama.initContainer.waitValkey" $ }}
*/}}
{{- define "tazama.initContainer.waitValkey" -}}
{{- $valkeyMode := include "tazama.infrastructure.mode" (dict "component" "valkey" "context" .) -}}
{{- if or (eq $valkeyMode "internal") (eq $valkeyMode "external") -}}
  {{- "true" -}}
{{- end }}
{{- end }}

{{/*
Determine if NATS wait initContainer should be rendered.
Returns: "true" or "" (falsy)

Usage: {{ include "tazama.initContainer.waitNats" $ }}
*/}}
{{- define "tazama.initContainer.waitNats" -}}
{{- $natsMode := include "tazama.infrastructure.mode" (dict "component" "nats" "context" .) -}}
{{- if or (eq $natsMode "internal") (eq $natsMode "external") -}}
  {{- "true" -}}
{{- end }}
{{- end }}

{{/*
Get the wait command for database initContainer.
Returns: shell command to wait for database connectivity

Usage: {{ include "tazama.initContainer.waitDbCommand" $ }}
*/}}
{{- define "tazama.initContainer.waitDbCommand" -}}
{{- $host := include "tazama.database.host" (dict "component" "postgres" "context" .) -}}
{{- $port := include "tazama.database.port" (dict "component" "postgres" "context" .) -}}
{{- printf "until nc -z %s %d; do sleep 2; done" $host (int $port) -}}
{{- end }}

{{/*
Get the wait command for Valkey initContainer.
Returns: shell command to wait for Valkey connectivity

Usage: {{ include "tazama.initContainer.waitValkeyCommand" $ }}
*/}}
{{- define "tazama.initContainer.waitValkeyCommand" -}}
{{- $host := include "tazama.valkey.host" . -}}
{{- $port := include "tazama.valkey.port" . -}}
{{- printf "until nc -z %s %d; do sleep 2; done" $host (int $port) -}}
{{- end }}

{{/*
Get the wait command for NATS initContainer.
Returns: shell command to wait for NATS connectivity

Usage: {{ include "tazama.initContainer.waitNatsCommand" $ }}
*/}}
{{- define "tazama.initContainer.waitNatsCommand" -}}
{{- $url := include "tazama.nats.url" . -}}
{{- $parts := split ":" $url -}}
{{- printf "until nc -z %s %s; do sleep 2; done" $parts._0 $parts._1 -}}
{{- end }}
