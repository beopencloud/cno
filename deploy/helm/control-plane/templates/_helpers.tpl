{{/*
Expand the name of the chart.
*/}}
{{- define "cno-chart.topicOperatorImage" -}}
{{- printf "%s/%s/%s:%s" .Values.strimziOperator.image.registry .Values.strimziOperator.image.repository .Values.strimziOperator.image.name .Values.strimziOperator.image.tag }}
{{- end }}

{{- define "cno-chart.userOperatorImage" -}}
{{- printf "%s/%s/%s:%s" .Values.strimziOperator.image.registry .Values.strimziOperator.image.repository .Values.strimziOperator.image.name .Values.strimziOperator.image.tag }}
{{- end }}

{{- define "cno-chart.keycloakAdminSecret" -}}
{{- if hasKey .Values.keycloakConfig.admin "secret" }}
{{- .Values.keycloakConfig.admin.secret.name }}
{{- else }}
{{- "cno-keycloak-admin" }}
{{- end }}
{{- end }}

{{- define "cno-chart.databaseConfig" -}}
- name: DB_HOST
  value: {{ .Values.databaseConfig.host }}
- name: DB_PORT
  value: {{ .Values.databaseConfig.port | quote }}
- name: DB_NAME
  value: {{ .Values.databaseConfig.database }}
- name: DB_USERNAME
  valueFrom:
    secretKeyRef:
      name: {{ .Values.databaseConfig.secret.name }}
      key: {{ .Values.databaseConfig.secret.usernameKey }}
- name: DB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ .Values.databaseConfig.secret.name }}
      key: {{ .Values.databaseConfig.secret.passwordKey }}
{{- end }}

{{- define "cno-chart.licenceSecret" -}}
{{- if hasKey .Values.agentConfig.cnoAgent.licence "secret" }}
{{- .Values.agentConfig.cnoAgent.licence.secret.name }}
{{- else }}
{{- "licence" }}
{{- end }}
{{- end }}

{{- define "cno-chart.apiProtocol" -}}
{{- if  .Values.agentConfig.defaultCluster }}
{{- "http" }}
{{- else }}
{{- .Values.global.cnoAPI.protocol }}
{{- end }}
{{- end }}

{{- define "cno-chart.clusterAgentUuid" -}}
{{- printf "7716124d-24e8-4ab2-abd8-90c638a12f89" }}
{{- end }}
