$content = Get-Content values-internal.yaml -Raw
$content = $content -replace 'memory: "64Mi"','memory: "2Gi"'
$content | Set-Content values-internal.yaml -NoNewline
