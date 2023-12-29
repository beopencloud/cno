{{- define "cno-agent.licenceSecret" -}}
{{- if hasKey .Values.cnoAgent.licence "secret" }}
{{- .Values.cnoAgent.licence.secret.name }}
{{- else }}
{{- "my-licence" }}
{{- end }}
{{- end }}

{{- define "cno-agent.cnoAPIUrl" -}}
{{- if hasKey .Values.global.cnoAPI "internalServiceName" }}
{{- printf "http://%s" .Values.global.cnoAPI.internalServiceName }}
{{- else }}
{{- .Values.global.cnoAPI.externalUrl }}
{{- end }}
{{- end }}

{{- define "cno-agent.apiProtocol" -}}
{{- if  .Values.defaultCluster }}
{{- "http" }}
{{- else }}
{{- .Values.global.cnoAPI.protocol }}
{{- end }}
{{- end }}
