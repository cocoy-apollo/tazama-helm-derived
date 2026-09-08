$content = Get-Content values-internal.yaml -Raw
$content = $content -replace 'memory: "256Mi"','memory: "2Gi"'
$content = $content -replace 'memory: "512Mi"','memory: "2Gi"'
$content = $content -replace 'memory: "1Gi"','memory: "2Gi"'
$content | Set-Content values-internal.yaml -NoNewline
