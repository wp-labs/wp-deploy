{{/* Expand the name of the chart. */}}
{{- define "station.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/* Create a default fully qualified app name. */}}
{{- define "station.fullname" -}}
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
{{- define "station.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/* Common labels. */}}
{{- define "station.labels" -}}
helm.sh/chart: {{ include "station.chart" . }}
{{ include "station.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/* Selector labels. */}}
{{- define "station.selectorLabels" -}}
app.kubernetes.io/name: {{ include "station.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/* ServiceAccount name. */}}
{{- define "station.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "station.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{- define "station.postgresName" -}}
{{- printf "%s-postgres" (include "station.fullname" .) }}
{{- end }}

{{- define "station.giteaName" -}}
{{- printf "%s-gitea" (include "station.fullname" .) }}
{{- end }}

{{- define "station.stationConfigName" -}}
{{- printf "%s-config" (include "station.fullname" .) }}
{{- end }}

{{- define "station.defaultConfigsName" -}}
{{- printf "%s-default-configs" (include "station.fullname" .) }}
{{- end }}

{{- define "station.initdbConfigName" -}}
{{- printf "%s-initdb" (include "station.fullname" .) }}
{{- end }}

{{- define "station.secretName" -}}
{{- printf "%s-secret" (include "station.fullname" .) }}
{{- end }}

{{- define "station.postgresPvcName" -}}
{{- printf "%s-data" (include "station.postgresName" .) }}
{{- end }}

{{- define "station.giteaPvcName" -}}
{{- printf "%s-data" (include "station.giteaName" .) }}
{{- end }}
