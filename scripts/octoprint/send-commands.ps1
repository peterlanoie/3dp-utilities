[CmdletBinding()]
param (
	[Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
	[string[]] $gcode,

	[switch]$echo,

	[switch]$noinfo
)

$ErrorActionPreference = 'Stop'

if (Test-Path -Path "$gcode") {
	if(!$noinfo){
		Write-Host "Reading GCODE from file '$gcode'"
	}
	$commands = Get-Content -Path $gcode
} else {
	if(!$noinfo){
		Write-Host "GCODE commands provided in argument"
		Write-Host "Command count: $($commands.Length)"
	}
	$commands = @(
		$gcode
	)
}

if ($echo) {
	$n = 1
	Write-Host "===== GCODE Commands ====="
	foreach ($line in $commands) {
		Write-Host "$n : $line"
		$n++
	}
	Write-Host "=========================="
}

$payload = @{
	commands = $commands
	parameters = @{}
}

#$payload

."$PSScriptRoot\call-api.ps1" -operation "printer/command" -method Post -payload $payload

# $response = (Invoke-WebRequest "$($apiConfig.Url)/$operationUrl" -Headers $($apiConfig.Headers) -Body ($payload | ConvertTo-Json) -Method $operationMethod)
# $response.Content | ConvertFrom-Json | ConvertTo-Json -Depth 100