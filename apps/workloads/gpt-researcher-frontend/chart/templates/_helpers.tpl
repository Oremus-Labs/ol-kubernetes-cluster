{{- define "gpt-researcher-frontend.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "gpt-researcher-frontend.fullname" -}}
{{- printf "%s-%s" .Release.Name (include "gpt-researcher-frontend.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
