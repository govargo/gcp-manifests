{{/*
Expand the name of the chart for realtime.
*/}}
{{- define "little-quest-realtime.name" -}}
{{- default .Chart.Name .Values.realtime.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Expand the name of the chart for frontend.
*/}}
{{- define "little-quest-frontend.name" -}}
{{- default "little-quest-frontend" .Values.frontend.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Expand the name of the chart for mmf.
*/}}
{{- define "little-quest-mmf.name" -}}
{{- default "little-quest-mmf" .Values.mmf.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Expand the name of the chart for director.
*/}}
{{- define "little-quest-director.name" -}}
{{- default "little-quest-director" .Values.director.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified realtime name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "little-quest-realtime.fullname" -}}
{{- if .Values.realtime.fullnameOverride }}
{{- .Values.realtime.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.realtime.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create a default fully qualified frontend name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "little-quest-frontend.fullname" -}}
{{- if .Values.frontend.fullnameOverride }}
{{- .Values.frontend.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default "little-quest-frontend" .Values.frontend.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s" $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create a default fully qualified mmf name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "little-quest-mmf.fullname" -}}
{{- if .Values.mmf.fullnameOverride }}
{{- .Values.mmf.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default "little-quest-mmf" .Values.mmf.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s" $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create a default fully qualified director name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "little-quest-director.fullname" -}}
{{- if .Values.director.fullnameOverride }}
{{- .Values.director.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default "little-quest-director" .Values.director.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s" $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "little-quest-realtime.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels for realtime
*/}}
{{- define "little-quest-realtime.labels" -}}
helm.sh/chart: {{ include "little-quest-realtime.chart" . }}
{{ include "little-quest-realtime.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Common labels for frontend
*/}}
{{- define "little-quest-frontend.labels" -}}
helm.sh/chart: {{ include "little-quest-realtime.chart" . }}
{{ include "little-quest-frontend.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Common labels for mmf
*/}}
{{- define "little-quest-mmf.labels" -}}
helm.sh/chart: {{ include "little-quest-realtime.chart" . }}
{{ include "little-quest-mmf.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Common labels for director
*/}}
{{- define "little-quest-director.labels" -}}
helm.sh/chart: {{ include "little-quest-realtime.chart" . }}
{{ include "little-quest-director.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels for realtime
*/}}
{{- define "little-quest-realtime.selectorLabels" -}}
app.kubernetes.io/name: {{ include "little-quest-realtime.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Selector labels for frontend
*/}}
{{- define "little-quest-frontend.selectorLabels" -}}
app.kubernetes.io/name: {{ include "little-quest-frontend.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Selector labels for mmf
*/}}
{{- define "little-quest-mmf.selectorLabels" -}}
app.kubernetes.io/name: {{ include "little-quest-mmf.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Selector labels for director
*/}}
{{- define "little-quest-director.selectorLabels" -}}
app.kubernetes.io/name: {{ include "little-quest-director.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use for realtime
*/}}
{{- define "little-quest-realtime.serviceAccountName" -}}
{{- if .Values.realtime.serviceAccount.create }}
{{- default (include "little-quest-realtime.fullname" .) .Values.realtime.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.realtime.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create the name of the service account to use for frontend
*/}}
{{- define "little-quest-frontend.serviceAccountName" -}}
{{- if .Values.frontend.serviceAccount.create }}
{{- default (include "little-quest-frontend.fullname" .) .Values.frontend.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.frontend.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create the name of the service account to use for mmf
*/}}
{{- define "little-quest-mmf.serviceAccountName" -}}
{{- if .Values.mmf.serviceAccount.create }}
{{- default (include "little-quest-mmf.fullname" .) .Values.mmf.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.mmf.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create the name of the service account to use for director
*/}}
{{- define "little-quest-director.serviceAccountName" -}}
{{- if .Values.director.serviceAccount.create }}
{{- default (include "little-quest-director.fullname" .) .Values.director.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.director.serviceAccount.name }}
{{- end }}
{{- end }}
