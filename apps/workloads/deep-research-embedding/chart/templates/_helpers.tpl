{{- define "deep-research-embedding.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride -}}
{{- else -}}
{{- printf "%s" .Chart.Name -}}
{{- end -}}
{{- end -}}
