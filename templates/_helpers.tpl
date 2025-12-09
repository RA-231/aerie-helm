{{/*
Expand the name of the chart.
*/}}
{{- define "aerie.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "aerie.fullname" -}}
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

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "aerie.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "aerie.labels" -}}
helm.sh/chart: {{ include "aerie.chart" . }}
{{ include "aerie.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "aerie.selectorLabels" -}}
app.kubernetes.io/name: {{ include "aerie.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Component labels - call with dict "root" . "component" "component-name"
*/}}
{{- define "aerie.componentLabels" -}}
{{ include "aerie.labels" .root }}
app.kubernetes.io/component: {{ .component }}
{{- end }}

{{/*
Component selector labels
*/}}
{{- define "aerie.componentSelectorLabels" -}}
{{ include "aerie.selectorLabels" .root }}
app.kubernetes.io/component: {{ .component }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "aerie.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "aerie.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Get the image tag, defaulting to global.imageTag
*/}}
{{- define "aerie.imageTag" -}}
{{- .tag | default $.root.Values.global.imageTag | default "latest" }}
{{- end }}

{{/*
Build full image name from registry + repository + tag
Usage: include "aerie.image" (dict "root" . "repository" .Values.component.image.repository "tag" .Values.component.image.tag)
*/}}
{{- define "aerie.image" -}}
{{- $registry := .root.Values.global.imageRegistry -}}
{{- $repo := .repository -}}
{{- $tag := .tag | default .root.Values.global.imageTag | default "latest" -}}
{{- if $registry -}}
{{- printf "%s/%s:%s" $registry $repo $tag -}}
{{- else -}}
{{- printf "%s:%s" $repo $tag -}}
{{- end -}}
{{- end }}

{{/*
PostgreSQL host - either internal service or external
*/}}
{{- define "aerie.postgresql.host" -}}
{{- if .Values.postgresql.enabled }}
{{- printf "%s-postgres" (include "aerie.fullname" .) }}
{{- else }}
{{- required "externalPostgresql.host is required when postgresql.enabled=false" .Values.externalPostgresql.host }}
{{- end }}
{{- end }}

{{/*
PostgreSQL port
*/}}
{{- define "aerie.postgresql.port" -}}
{{- if .Values.postgresql.enabled }}
{{- 5432 }}
{{- else }}
{{- .Values.externalPostgresql.port | default 5432 }}
{{- end }}
{{- end }}

{{/*
PostgreSQL database name
*/}}
{{- define "aerie.postgresql.database" -}}
{{- if .Values.postgresql.enabled }}
{{- "aerie" }}
{{- else }}
{{- .Values.externalPostgresql.database | default "aerie" }}
{{- end }}
{{- end }}

{{/*
Name of the secret containing database credentials
*/}}
{{- define "aerie.postgresql.secretName" -}}
{{- if and (not .Values.postgresql.enabled) .Values.externalPostgresql.existingSecret }}
{{- .Values.externalPostgresql.existingSecret }}
{{- else }}
{{- printf "%s-db-credentials" (include "aerie.fullname" .) }}
{{- end }}
{{- end }}

{{/*
Hasura service URL (internal)
*/}}
{{- define "aerie.hasura.url" -}}
{{- printf "http://%s-hasura:%d" (include "aerie.fullname" .) (.Values.hasura.service.port | int) }}
{{- end }}

{{/*
Hasura GraphQL URL (internal)
*/}}
{{- define "aerie.hasura.graphqlUrl" -}}
{{- printf "%s/v1/graphql" (include "aerie.hasura.url" .) }}
{{- end }}

{{/*
Merlin server URL (internal)
*/}}
{{- define "aerie.merlin.url" -}}
{{- printf "http://%s-merlin:%d" (include "aerie.fullname" .) (.Values.merlin.server.port | int) }}
{{- end }}

{{/*
Scheduler server URL (internal)
*/}}
{{- define "aerie.scheduler.url" -}}
{{- printf "http://%s-scheduler:%d" (include "aerie.fullname" .) (.Values.scheduler.server.port | int) }}
{{- end }}

{{/*
Sequencing server URL (internal)
*/}}
{{- define "aerie.sequencing.url" -}}
{{- printf "http://%s-sequencing:%d" (include "aerie.fullname" .) (.Values.sequencing.port | int) }}
{{- end }}

{{/*
Gateway URL (internal)
*/}}
{{- define "aerie.gateway.url" -}}
{{- printf "http://%s-gateway:%d" (include "aerie.fullname" .) (.Values.gateway.port | int) }}
{{- end }}

{{/*
Action server URL (internal)
*/}}
{{- define "aerie.action.url" -}}
{{- printf "http://%s-action:%d" (include "aerie.fullname" .) (.Values.action.port | int) }}
{{- end }}

{{/*
Workspace server URL (internal)
*/}}
{{- define "aerie.workspace.url" -}}
{{- printf "http://%s-workspace:%d" (include "aerie.fullname" .) (.Values.workspace.port | int) }}
{{- end }}

{{/*
File store PVC name
*/}}
{{- define "aerie.fileStore.pvcName" -}}
{{- printf "%s-file-store" (include "aerie.fullname" .) }}
{{- end }}

{{/*
Workspace file store PVC name
*/}}
{{- define "aerie.workspace.pvcName" -}}
{{- printf "%s-workspace-store" (include "aerie.fullname" .) }}
{{- end }}

{{/*
Postgres data PVC name
*/}}
{{- define "aerie.postgres.pvcName" -}}
{{- printf "%s-postgres-data" (include "aerie.fullname" .) }}
{{- end }}

{{/*
Database URL for Hasura (with search_path)
Uses URL-encoded password variable set by init container
*/}}
{{- define "aerie.hasura.databaseUrl" -}}
{{- $host := include "aerie.postgresql.host" . }}
{{- $port := include "aerie.postgresql.port" . }}
{{- printf "postgres://$(AERIE_DB_USER_ENCODED):$(AERIE_DB_PASSWORD_ENCODED)@%s:%s/aerie?options=-c%%20search_path%%3Dutil_functions%%2Chasura%%2Cpermissions%%2Ctags%%2Cmerlin%%2Cscheduler%%2Csequencing%%2Cactions%%2Cui%%2Cpublic" $host (toString $port) }}
{{- end }}

{{/*
Hasura metadata database URL
Uses URL-encoded password variable set by init container
*/}}
{{- define "aerie.hasura.metadataDatabaseUrl" -}}
{{- $host := include "aerie.postgresql.host" . }}
{{- $port := include "aerie.postgresql.port" . }}
{{- printf "postgres://$(AERIE_DB_USER_ENCODED):$(AERIE_DB_PASSWORD_ENCODED)@%s:%s/aerie_hasura" $host (toString $port) }}
{{- end }}

{{/*
Shell script to URL-encode a string (POSIX compatible)
*/}}
{{- define "aerie.urlEncodeScript" -}}
urlencode() {
  local string="$1"
  local strlen=${#string}
  local encoded=""
  local pos c o
  for (( pos=0 ; pos<strlen ; pos++ )); do
    c=${string:$pos:1}
    case "$c" in
      [-_.~a-zA-Z0-9] ) o="$c" ;;
      * ) printf -v o '%%%02X' "'$c" ;;
    esac
    encoded+="$o"
  done
  echo "$encoded"
}
{{- end }}
