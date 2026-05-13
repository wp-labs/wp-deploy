{{/* Expand the name of the chart. */}}
{{- define "wparse.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/* Create a default fully qualified app name. */}}
{{- define "wparse.fullname" -}}
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

{{/* Create chart name and version label. */}}
{{- define "wparse.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/* Common labels. */}}
{{- define "wparse.labels" -}}
helm.sh/chart: {{ include "wparse.chart" . }}
{{ include "wparse.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/* Selector labels. */}}
{{- define "wparse.selectorLabels" -}}
app.kubernetes.io/name: {{ include "wparse.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/* Create the service account name. */}}
{{- define "wparse.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "wparse.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/* Secret name for /root/.warp_parse. */}}
{{- define "wparse.warpParseSecretName" -}}
{{- default (printf "%s-warp-parse" (include "wparse.fullname" .)) .Values.wparse.warpParseSecret.existingSecret }}
{{- end }}

{{/* Whether the chart bundles an admin token file. */}}
{{- define "wparse.hasBundledWarpParseToken" -}}
{{- if .Files.Get ".warp_parse/admin_api.token" }}true{{- end }}
{{- end }}

{{/* Whether the chart bundles a complete TLS keypair. */}}
{{- define "wparse.hasBundledWarpParseTls" -}}
{{- $crt := .Files.Get ".warp_parse/tls/server.crt" -}}
{{- $key := .Files.Get ".warp_parse/tls/server.key" -}}
{{- if or (and $crt (not $key)) (and $key (not $crt)) }}
{{- fail "both .warp_parse/tls/server.crt and .warp_parse/tls/server.key must be provided together" }}
{{- end }}
{{- if and $crt $key }}true{{- end }}
{{- end }}

{{/* Whether a WarpParse secret should be mounted. */}}
{{- define "wparse.hasWarpParseSecret" -}}
{{- if or .Values.wparse.warpParseSecret.existingSecret (include "wparse.hasBundledWarpParseToken" .) }}true{{- end }}
{{- end }}
