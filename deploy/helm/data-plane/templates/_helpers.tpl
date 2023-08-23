{{- define "boor-agent.licenceSecret" -}}
{{- if hasKey .Values.boorAgent.licence "secret" }}
{{- .Values.boorAgent.licence.secret.name }}
{{- else }}
{{- "my-licence" }}
{{- end }}
{{- end }}

{{- define "boor-agent.boorAPIUrl" -}}
{{- if hasKey .Values.global.boorAPI "internalServiceName" }}
{{- printf "http://%s" .Values.global.boorAPI.internalServiceName }}
{{- else }}
{{- .Values.global.boorAPI.externalUrl }}
{{- end }}
{{- end }}

{{- define "boor-agent.apiProtocol" -}}
{{- if  .Values.defaultCluster }}
{{- "http" }}
{{- else }}
{{- .Values.global.boorAPI.protocol }}
{{- end }}
{{- end }}
