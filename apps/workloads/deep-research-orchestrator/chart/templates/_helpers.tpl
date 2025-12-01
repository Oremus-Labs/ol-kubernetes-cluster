{{- define "deep-research-orchestrator.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride -}}
{{- else -}}
{{- printf "%s" .Chart.Name -}}
{{- end -}}
{{- end -}}
