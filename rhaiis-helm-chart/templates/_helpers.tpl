{{/*
Expand the name of the chart.
*/}}
{{- define "rhaiis.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "rhaiis.fullname" -}}
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
{{- define "rhaiis.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "rhaiis.labels" -}}
helm.sh/chart: {{ include "rhaiis.chart" . }}
{{ include "rhaiis.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "rhaiis.selectorLabels" -}}
app.kubernetes.io/name: {{ include "rhaiis.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app: {{ .Values.labels.app }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "rhaiis.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "rhaiis.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Generate the namespace
*/}}
{{- define "rhaiis.namespace" -}}
{{- default .Release.Namespace .Values.global.namespace }}
{{- end }}

{{/*
Generate the cache PVC name
*/}}
{{- define "rhaiis.cachePvcName" -}}
{{- printf "%s-%s" (include "rhaiis.fullname" .) .Values.storage.cache.name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Generate the model cache PVC name
*/}}
{{- define "rhaiis.modelCachePvcName" -}}
{{- printf "%s-%s" (include "rhaiis.fullname" .) .Values.storage.modelCache.name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Generate the secret name
*/}}
{{- define "rhaiis.secretName" -}}
{{- printf "%s-%s" (include "rhaiis.fullname" .) .Values.secrets.huggingface.name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Generate the service name
*/}}
{{- define "rhaiis.serviceName" -}}
{{- printf "%s-%s" (include "rhaiis.fullname" .) .Values.service.name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Generate the route name
*/}}
{{- define "rhaiis.routeName" -}}
{{- printf "%s-%s" (include "rhaiis.fullname" .) .Values.route.name | trunc 63 | trimSuffix "-" }}
{{- end }}
