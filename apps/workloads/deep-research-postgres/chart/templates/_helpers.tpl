{{- define "deep-research-postgres.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride -}}
{{- else -}}
{{- printf "%s" .Chart.Name -}}
{{- end -}}
{{- end -}}
