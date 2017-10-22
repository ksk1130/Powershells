param(
[string]$targetDir
,[int]$maxViewNum=20
)

Get-ChildItem $targetDir -Recurse -ErrorAction SilentlyContinue |`
 Where-Object{$_.PSIsContainer -ne $true} |`
   Sort-Object Length -Descending |`
     Select-Object FullName,@{label="SIZE(MB)"; expression={"{0:#,0.00}MB" -f ($_.Length / 1MB)}} -First $maxViewNum