{{- define "nginx-push-stream-module.fullname" -}}
{{ tpl .Values.fullname . | trunc 63 | trimSuffix "-" }}
{{- end -}}