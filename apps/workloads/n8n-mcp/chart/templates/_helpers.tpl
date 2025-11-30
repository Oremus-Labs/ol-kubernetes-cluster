{{- define "n8n-mcp-wrapper.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "n8n-mcp-wrapper.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "n8n-mcp-wrapper.labels" -}}
helm.sh/chart: {{ include "n8n-mcp-wrapper.chart" . }}
{{ include "n8n-mcp-wrapper.selectorLabels" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{- define "n8n-mcp-wrapper.selectorLabels" -}}
app.kubernetes.io/name: {{ include "n8n-mcp-wrapper.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "n8n-mcp-wrapper.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" -}}
{{- end -}}

{{- define "n8n-mcp-wrapper.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- default (include "n8n-mcp-wrapper.fullname" .) .Values.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.serviceAccount.name -}}
{{- end -}}
{{- end -}}
