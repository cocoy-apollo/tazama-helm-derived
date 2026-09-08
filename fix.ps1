$c = Get-Content templates\typologies\typologies.yaml 
$c[84] = '          image: \\\"busybox:1.36\\\"' 
$c[98] = '          image: \\\"busybox:1.36\\\"' 
$c | Set-Content templates\typologies\typologies.yaml -Encoding UTF8 
