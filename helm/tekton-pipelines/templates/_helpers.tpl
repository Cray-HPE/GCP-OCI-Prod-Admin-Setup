{{/*
Expand the name of the chart.
*/}}
{{- define "tektonPipelines.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "tektonPipelines.fullname" -}}
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


{{- define "tektonPipelines.labels" -}}
app.kubernetes.io/instance: {{ template "tektonPipelines.fullname". }}
app.kubernetes.io/part-of: tekton-pipelines
helm-release: {{ .Release.Name | quote }}
helm.sh/chart: "{{ .Chart.Name }}-{{ .Chart.Version}}"
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}

{{- define "tektonPipelines.labelselector" -}}
app.kubernetes.io/instance: {{ template "tektonPipelines.fullname". }}
app.kubernetes.io/part-of: tekton-pipelines
{{- end }}


{{/*
Create the image path for the passed in image field
*/}}
{{- define "pipelineDeployment.image" -}}
{{- printf "%s:%s@%s" .repository .tag .digest -}}
{{- end -}}

{{- define "pipelinesWebhook.image" -}}
{{- printf "%s:%s@%s" .repository .tag .digest -}}
{{- end -}}

{{- define "pipelineDeployment.argsImages" -}}
{{- $list := list -}}
{{- range $k, $v := .Values.pipelineDeployment.args -}}
{{- $list = append $list (printf "\"-%s\",\"%s\"" $v.name $v.image) -}}
{{- end -}}
{{ join ", " $list }}
{{- end -}}

