{{- define "gpt-researcher.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "gpt-researcher.fullname" -}}
{{- printf "%s-%s" .Release.Name (include "gpt-researcher.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
