{{/*
Expand the name of the chart.
*/}}
{{- define "tektonChains.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "tektonChains.image" -}}
{{- printf "%s:%s@%s" .repository .tag .digest -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "tektonChains.fullname" -}}
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

{{ define "tektonChains.labels" -}}
app.kubernetes.io/component: chains
app.kubernetes.io/instance: default
app.kubernetes.io/part-of: tekton-pipelines
pipeline.tekton.dev/release: "devel"
version: {{ .Chart.AppVersion | quote}}
{{- end -}}

