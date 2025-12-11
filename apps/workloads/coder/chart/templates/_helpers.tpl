{{- define "coder-wrapper.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "coder-wrapper.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "coder-wrapper.labels" -}}
helm.sh/chart: {{ .Chart.Name }}
app.kubernetes.io/name: {{ include "coder-wrapper.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{- define "coder-wrapper.selectorLabels" -}}
app.kubernetes.io/name: {{ include "coder-wrapper.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "coder-wrapper.postgresLabels" -}}
app.kubernetes.io/component: postgres
{{ include "coder-wrapper.selectorLabels" . }}
{{- end -}}

{{- define "coder-wrapper.postgresServiceName" -}}
{{- default (printf "%s-postgres" (include "coder-wrapper.fullname" .)) .Values.postgres.serviceName -}}
{{- end -}}
