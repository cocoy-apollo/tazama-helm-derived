heres my external services yaml

{{/*
External Infrastructure Services
Creates ExternalName Services when external infrastructure is enabled,
allowing in-cluster services to resolve external endpoints via Kubernetes DNS.
*/}}

{{/*
PostgreSQL External Service
Creates an ExternalName Service pointing to external PostgreSQL when:
- infrastructure.postgres.enabled is false AND
- infrastructure.postgres.external.enabled is true
*/}}
{{- if and (not (include "tazama.infrastructure.internal.enabled" (dict "component" "postgres" "context" $) | eq "true")) (include "tazama.infrastructure.external.enabled" (dict "component" "postgres" "context" $) | eq "true") }}
apiVersion: v1
kind: Service
metadata:
  name: postgres
  labels:
    {{- include "tazama.labels" . | nindent 4 }}
    app.kubernetes.io/component: database
    infrastructure.tazama.io/type: external
    infrastructure.tazama.io/service: postgres
  annotations:
    infrastructure.tazama.io/external-host: {{ .Values.infrastructure.postgres.external.host | quote }}
    infrastructure.tazama.io/external-port: {{ .Values.infrastructure.postgres.external.port | quote }}
    infrastructure.tazama.io/ssl-enabled: {{ .Values.infrastructure.postgres.external.ssl.enabled | quote }}
spec:
  type: ExternalName
  externalName: {{ .Values.infrastructure.postgres.external.host }}
  ports:
    - name: postgresql
      port: {{ .Values.infrastructure.postgres.external.port }}
      targetPort: {{ .Values.infrastructure.postgres.external.port }}
      protocol: TCP
---
{{- end }}

{{/*
Valkey/Redis External Service
Creates an ExternalName Service pointing to external Valkey/Redis when:
- infrastructure.valkey.enabled is false AND
- infrastructure.valkey.external.enabled is true
*/}}
{{- if and (not (include "tazama.infrastructure.internal.enabled" (dict "component" "valkey" "context" $) | eq "true")) (include "tazama.infrastructure.external.enabled" (dict "component" "valkey" "context" $) | eq "true") }}
apiVersion: v1
kind: Service
metadata:
  name: valkey
  labels:
    {{- include "tazama.labels" . | nindent 4 }}
    app.kubernetes.io/component: cache
    infrastructure.tazama.io/type: external
    infrastructure.tazama.io/service: valkey
  annotations:
    infrastructure.tazama.io/external-host: {{ .Values.infrastructure.valkey.external.host | quote }}
    infrastructure.tazama.io/external-port: {{ .Values.infrastructure.valkey.external.port | quote }}
    infrastructure.tazama.io/ssl-enabled: {{ .Values.infrastructure.valkey.external.ssl.enabled | quote }}
    {{- if .Values.infrastructure.valkey.external.cluster.enabled }}
    infrastructure.tazama.io/cluster-enabled: "true"
    {{- end }}
spec:
  type: ExternalName
  externalName: {{ .Values.infrastructure.valkey.external.host }}
  ports:
    - name: valkey
      port: {{ .Values.infrastructure.valkey.external.port }}
      targetPort: {{ .Values.infrastructure.valkey.external.port }}
      protocol: TCP
---
{{- end }}

{{/*
NATS External Service
Creates an ExternalName Service pointing to external NATS when:
- infrastructure.nats.enabled is false AND  
- infrastructure.nats.external.enabled is true
*/}}
{{- if and (not (include "tazama.infrastructure.internal.enabled" (dict "component" "nats" "context" $) | eq "true")) (include "tazama.infrastructure.external.enabled" (dict "component" "nats" "context" $) | eq "true") }}
apiVersion: v1
kind: Service
metadata:
  name: nats
  labels:
    {{- include "tazama.labels" . | nindent 4 }}
    app.kubernetes.io/component: messaging
    infrastructure.tazama.io/type: external
    infrastructure.tazama.io/service: nats
  annotations:
    infrastructure.tazama.io/external-host: {{ .Values.infrastructure.nats.external.host | quote }}
    infrastructure.tazama.io/external-port: {{ .Values.infrastructure.nats.external.port | quote }}
    infrastructure.tazama.io/ssl-enabled: {{ .Values.infrastructure.nats.external.ssl.enabled | quote }}
    {{- if .Values.infrastructure.nats.external.cluster.enabled }}
    infrastructure.tazama.io/cluster-enabled: "true"
    {{- end }}
spec:
  type: ExternalName
  externalName: {{ .Values.infrastructure.nats.external.host }}
  ports:
    - name: nats
      port: {{ .Values.infrastructure.nats.external.port }}
      targetPort: {{ .Values.infrastructure.nats.external.port }}
      protocol: TCP
---
{{- end }}

{{/*
Additional NATS Monitoring Port (optional)
Creates additional ExternalName Service for NATS monitoring endpoint if specified
*/}}
{{- if and (not (include "tazama.infrastructure.internal.enabled" (dict "component" "nats" "context" $) | eq "true")) (include "tazama.infrastructure.external.enabled" (dict "component" "nats" "context" $) | eq "true") .Values.infrastructure.nats.external.monitoring }}
apiVersion: v1
kind: Service
metadata:
  name: nats-monitoring
  labels:
    {{- include "tazama.labels" . | nindent 4 }}
    app.kubernetes.io/component: messaging-monitoring
    infrastructure.tazama.io/type: external
    infrastructure.tazama.io/service: nats-monitoring
spec:
  type: ExternalName
  externalName: {{ .Values.infrastructure.nats.external.host }}
  ports:
    - name: monitoring
      port: {{ .Values.infrastructure.nats.external.monitoring.port | default 8222 }}
      targetPort: {{ .Values.infrastructure.nats.external.monitoring.port | default 8222 }}
      protocol: TCP
---
{{- end }}

{{/*
Valkey Cluster Service (for cluster mode)
When Valkey cluster mode is enabled, creates additional ExternalName services
for each cluster node if nodes are specified
*/}}
{{- if and (not (include "tazama.infrastructure.internal.enabled" (dict "component" "valkey" "context" $) | eq "true")) (include "tazama.infrastructure.external.enabled" (dict "component" "valkey" "context" $) | eq "true") .Values.infrastructure.valkey.external.cluster.enabled .Values.infrastructure.valkey.external.cluster.nodes }}
{{- range $index, $node := .Values.infrastructure.valkey.external.cluster.nodes }}
apiVersion: v1
kind: Service
metadata:
  name: valkey-cluster-{{ $index }}
  labels:
    {{- include "tazama.labels" $ | nindent 4 }}
    app.kubernetes.io/component: cache-cluster
    infrastructure.tazama.io/type: external
    infrastructure.tazama.io/service: valkey-cluster
    infrastructure.tazama.io/cluster-node-index: {{ $index | quote }}
spec:
  type: ExternalName
  externalName: {{ required "Valkey cluster node host is required" $node.host }}
  ports:
    - name: valkey
      port: {{ $node.port | default 6379 }}
      targetPort: {{ $node.port | default 6379 }}
      protocol: TCP
---
{{- end }}
{{- end }}

{{/*
NATS Cluster Services (for cluster mode)
When NATS cluster mode is enabled, creates additional ExternalName services
for each cluster URL if specified
*/}}
{{- if and (not (include "tazama.infrastructure.internal.enabled" (dict "component" "nats" "context" $) | eq "true")) (include "tazama.infrastructure.external.enabled" (dict "component" "nats" "context" $) | eq "true") .Values.infrastructure.nats.external.cluster.enabled .Values.infrastructure.nats.external.cluster.urls }}
{{- range $index, $url := .Values.infrastructure.nats.external.cluster.urls }}
{{- $parsed := $url | trimPrefix "nats://" }}
apiVersion: v1
kind: Service
metadata:
  name: nats-cluster-{{ $index }}
  labels:
    {{- include "tazama.labels" $ | nindent 4 }}
    app.kubernetes.io/component: messaging-cluster
    infrastructure.tazama.io/type: external
    infrastructure.tazama.io/service: nats-cluster
    infrastructure.tazama.io/cluster-node-index: {{ $index | quote }}
spec:
  type: ExternalName
  externalName: {{ $parsed }}
  ports:
    - name: nats
      port: 4222
      targetPort: 4222
      protocol: TCP
---
{{- end }}
{{- end }}


valkey yaml

{{- /*
  valkey.yaml - Valkey (Redis-compatible) Deployment and Service
  Conditional rendering based on infrastructure.valkey.enabled
  
  C1, C3: Only rendered when internal valkey is enabled
  When external: user connects to external Redis/Valkey cluster
  
  FIX: Added emptyDir volume for data directory to support readOnlyRootFilesystem
  Valkey requires writable storage for:
  - dump.rdb (RDB snapshots)
  - AOF log files (if AOF persistence enabled)
  - Temporary rewrite buffers
*/ -}}
{{- if include "tazama.infrastructure.internal.enabled" (dict "component" "valkey" "context" $) }}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: valkey
  namespace: {{ .Release.Namespace }}
  labels:
    app.kubernetes.io/name: valkey
    app.kubernetes.io/component: cache
    app.kubernetes.io/part-of: tazama
    {{- include "tazama.labels" $ | nindent 4 }}
spec:
  replicas: 1
  selector:
    matchLabels:
      app: valkey
  template:
    metadata:
      labels:
        app: valkey
        app.kubernetes.io/name: valkey
        app.kubernetes.io/component: cache
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        runAsGroup: 1000
        fsGroup: 1000
        seccompProfile:
          type: RuntimeDefault
      containers:
        - name: valkey
          image: {{ .Values.infrastructure.valkey.image | default "valkey/valkey:8.0" | quote }}
          securityContext:
            allowPrivilegeEscalation: false
            capabilities:
              drop:
                - ALL
            runAsNonRoot: true
            runAsUser: 1000
            readOnlyRootFilesystem: true
          command: ["valkey-server"]
          args:
            - "--port"
            - "6379"
            - "--loglevel"
            - "verbose"
            - "--dir"
            - "/data"
            - "--save"
            - "60"
            - "1"
          ports:
            - containerPort: 6379
              name: valkeyport
          volumeMounts:
            - name: valkey-data
              mountPath: /data
          livenessProbe:
            tcpSocket:
              port: 6379
            initialDelaySeconds: 5
            periodSeconds: 10
          readinessProbe:
            tcpSocket:
              port: 6379
            initialDelaySeconds: 3
            periodSeconds: 5
          {{- if .Values.infrastructure.valkey.resources }}
          resources:
            {{- toYaml .Values.infrastructure.valkey.resources | nindent 12 }}
          {{- end }}
      volumes:
        - name: valkey-data
          emptyDir: {}
---
apiVersion: v1
kind: Service
metadata:
  name: valkey
  namespace: {{ .Release.Namespace }}
  labels:
    app.kubernetes.io/name: valkey
    app.kubernetes.io/component: cache
    app.kubernetes.io/part-of: tazama
spec:
  ports:
    - port: 6379
      targetPort: 6379
      name: valkeyport
  selector:
    app: valkey
{{- end }}

and nats yaml


{{- /*
  nats.yaml - NATS JetStream Deployment and Service
  Conditional rendering based on infrastructure.nats.enabled
  
  C1, C3: Only rendered when internal nats is enabled
  When external: user connects to external NATS cluster
  
  Features:
  - JetStream persistence (PVC-backed)
  - Health checks via HTTP monitoring endpoint
  
  NOTE: Connection limits (maxConnections, maxPayload, writeDeadline) are not
  supported as command-line flags by NATS server. Configure these via a
  nats-server config file if needed.
*/ -}}
{{- if include "tazama.infrastructure.internal.enabled" (dict "component" "nats" "context" $) }}
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: nats
  namespace: {{ .Release.Namespace }}
  labels:
    app.kubernetes.io/name: nats
    app.kubernetes.io/component: messaging
    app.kubernetes.io/part-of: tazama
    {{- include "tazama.labels" $ | nindent 4 }}
spec:
  serviceName: nats
  replicas: 1
  selector:
    matchLabels:
      app: nats
  template:
    metadata:
      labels:
        app: nats
        app.kubernetes.io/name: nats
        app.kubernetes.io/component: messaging
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        runAsGroup: 1000
        fsGroup: 1000
        seccompProfile:
          type: RuntimeDefault
      containers:
        - name: nats
          image: {{ .Values.infrastructure.nats.image | default "nats:2.10" | quote }}
          securityContext:
            allowPrivilegeEscalation: false
            capabilities:
              drop:
                - ALL
            runAsNonRoot: true
            runAsUser: 1000
            readOnlyRootFilesystem: true
          args:
            {{- if .Values.infrastructure.nats.jetStream.enabled }}
            # JetStream enabled - message persistence
            - "--jetstream"
            - "--store_dir=/data"
            {{- end }}
            # HTTP monitoring endpoint (required for readiness/liveness probes)
            - "-m"
            - "8222"
            # Debug flags
            - "-DVV"
          ports:
            - containerPort: 4222
              name: client
            - containerPort: 6222
              name: cluster
            - containerPort: 8222
              name: monitor
          volumeMounts:
            {{- if .Values.infrastructure.nats.jetStream.enabled }}
            - name: jetstream-storage
              mountPath: /data
            {{- end }}
          livenessProbe:
            httpGet:
              path: /healthz
              port: monitor
            initialDelaySeconds: 10
            periodSeconds: 30
          readinessProbe:
            httpGet:
              path: /healthz
              port: monitor
            initialDelaySeconds: 5
            periodSeconds: 10
          {{- if .Values.infrastructure.nats.resources }}
          resources:
            {{- toYaml .Values.infrastructure.nats.resources | nindent 12 }}
          {{- end }}
      volumes:
        {{- if .Values.infrastructure.nats.jetStream.enabled }}
        - name: jetstream-storage
          persistentVolumeClaim:
            claimName: nats-jetstream-pvc
        {{- end }}
---
{{- if .Values.infrastructure.nats.jetStream.enabled }}
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: nats-jetstream-pvc
  namespace: {{ .Release.Namespace }}
  labels:
    app.kubernetes.io/name: nats
    app.kubernetes.io/component: messaging
    app.kubernetes.io/part-of: tazama
spec:
  accessModes:
    - ReadWriteOnce
  {{- if .Values.global.storageClass }}
  storageClassName: {{ .Values.global.storageClass }}
  {{- end }}
  resources:
    requests:
      storage: {{ .Values.infrastructure.nats.jetStream.storageSize | default "5Gi" }}
---
{{- end }}
apiVersion: v1
kind: Service
metadata:
  name: nats
  namespace: {{ .Release.Namespace }}
  labels:
    app.kubernetes.io/name: nats
    app.kubernetes.io/component: messaging
    app.kubernetes.io/part-of: tazama
spec:
  ports:
    - name: client
      port: 4222
      targetPort: 4222
    - name: cluster
      port: 6222
      targetPort: 6222
    - name: monitor
      port: 8222
      targetPort: 8222
  selector:
    app: nats
{{- end }}
