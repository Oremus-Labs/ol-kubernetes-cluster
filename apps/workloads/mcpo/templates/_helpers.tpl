{{- define "mcpo.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "mcpo.fullname" -}}
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

{{- define "mcpo.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "mcpo.labels" -}}
helm.sh/chart: {{ include "mcpo.chart" . }}
{{ include "mcpo.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "mcpo.selectorLabels" -}}
app.kubernetes.io/name: {{ include "mcpo.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "mcpo.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "mcpo.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{- define "mcpo.namespace" -}}
{{- $global := default (dict) .Values.global -}}
{{- $coreNs := "" -}}
{{- if $global }}
  {{- $nsMap := default (dict) $global.namespaces -}}
  {{- $coreNs = default "" $nsMap.core -}}
{{- end }}
{{- coalesce .Values.targetNamespace $coreNs .Release.Namespace -}}
{{- end }}

{{- define "mcpo.podAnnotations" -}}
{{- $global := default (dict) .Values.global -}}
{{- $vault := dict -}}
{{- if $global }}
  {{- $vaultCfg := default (dict) $global.vault -}}
  {{- $vault = default (dict) $vaultCfg.annotations -}}
{{- end }}
{{- $component := default (dict) .Values.podAnnotations -}}
{{- $merged := merge (deepCopy $vault) (deepCopy $component) -}}
{{- if gt (len $merged) 0 -}}
{{- range $k, $v := $merged }}
{{ $k }}: {{ $v | quote }}
{{- end }}
{{- end -}}
{{- end }}
