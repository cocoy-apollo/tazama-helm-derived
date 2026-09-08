@echo off  
powershell -NoProfile -Command \"$f = 'templates/typologies/typologies.yaml'; $c = [IO.File]::ReadAllText($f); $c = $c -replace '{{ .Values.global.imageRegistry | default \\\"docker.io\\\" }}/busybox:1.36', 'busybox:1.36'; [IO.File]::WriteAllText($f, $c)\"  
