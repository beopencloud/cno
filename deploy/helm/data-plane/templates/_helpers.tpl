{{- define "door-agent.licenceSecret" -}}
{{- if hasKey .Values.doorAgent.licence "secret" }}
{{- .Values.doorAgent.licence.secret.name }}
{{- else }}
{{- "my-licence" }}
{{- end }}
{{- end }}

{{- define "door-agent.doorAPIUrl" -}}
{{- if hasKey .Values.global.doorAPI "internalServiceName" }}
{{- printf "http://%s" .Values.global.doorAPI.internalServiceName }}
{{- else }}
{{- .Values.global.doorAPI.externalUrl }}
{{- end }}
{{- end }}

{{- define "door-agent.apiProtocol" -}}
{{- if  .Values.defaultCluster }}
{{- "http" }}
{{- else }}
{{- .Values.global.doorAPI.protocol }}
{{- end }}
{{- end }}
