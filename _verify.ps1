$c = Get-Content 'd:\Physiqo\lib\services\ai_config_service.dart'
Write-Host "=== Keys (37-42) ==="
$c[36..41] | ForEach-Object { Write-Host $_ }
Write-Host "=== Export network (108-118) ==="
$c[107..117] | ForEach-Object { Write-Host $_ }
Write-Host "=== Import network (168-180) ==="
$c[167..179] | ForEach-Object { Write-Host $_ }
Write-Host "=== Clear (340-350) ==="
$c[339..349] | ForEach-Object { Write-Host $_ }