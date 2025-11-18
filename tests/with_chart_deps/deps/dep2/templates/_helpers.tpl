{{/*
Expand the name of the chart.
*/}}
{{- define "dep2.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}
