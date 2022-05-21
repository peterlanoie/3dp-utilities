."$PSScriptRoot/shared-resources.ps1"
Write-Host "Clearing the local file cache: $cacheFolder"
if (Test-Path $cacheFolder) {
	Remove-Item -Path $cacheFolder -Recurse -Force -Confirm:$false
}
