[CmdletBinding()]
param (
	[Parameter(Mandatory = $false)]
	[string] $operation = "version",

	[Parameter()]
	[ValidateSet("GET","POST")]
	[string] $method = "GET",

	[Parameter()]
	[object] $payload,

	[string] $serverAddress,
	[string] $apiKey,
	[switch] $nocache,

	[switch] $debugApi

)
$ErrorActionPreference = 'Stop';

."$PSScriptRoot/shared-resources.ps1"

function Invoke-OctoPrintApi {
	param (
		[string] $_operation,
		[string] $_method,
		[object] $_payload,
		[OctoPrintInfo] $_octoPrintInfo,
		[string] $_cacheFolder,
		[bool] $_debugApi
	)

	Write-Verbose "Call to $($MyInvocation.MyCommand.Name)"
	Write-Verbose "   Operation: $_operation"
	Write-Verbose "   Method: $_method"
	Write-Verbose "   Payload: $($_payload | ConvertTo-Json)"
	Write-Verbose "   OctoPrintInfo: $($_octoPrintInfo | ConvertTo-Json)"
	Write-Verbose "   cacheFolder: $_cacheFolder"
	Write-Verbose "   debugApi: $_debugApi"

	$apiConfig = @{
		Url = $_octoPrintInfo.address
		Headers = @{ 
			"X-Api-Key" = $_octoPrintInfo.apiKey
			"Content-Type" = "application/json"
		}
	}
	
	$endpointUrl = "$($apiConfig.Url)/api/$_operation"

	Write-Verbose "API operation: $_operation"
	Write-Verbose "Endpoint URL: $endpointUrl"
	Write-Verbose "Payload:"
	Write-Verbose "========"
	Write-Verbose $_payload # | ConvertTo-Json
	Write-Verbose "========"
	if ($_debugApi -or $Verbose) {
	}
	
	if ($_payload) {
		$payloadJson = ($_payload | ConvertTo-Json)
		$response = (Invoke-WebRequest "$endpointUrl" -Headers $($apiConfig.Headers) -Body $payloadJson -Method $_method)
	} else {
		$response = (Invoke-WebRequest "$endpointUrl" -Headers $($apiConfig.Headers) -Method $_method)
	}
	
	$response.Content | Out-File -FilePath "$_cacheFolder/last-response.json"

	return $response.Content | ConvertFrom-Json
}

if (!(Test-Path -Path $cacheFolder)) {
	New-Item -Path $cacheFolder -ItemType Directory | Out-Null
}

if (Test-Path -Path $infoFile) {
	$octoPrintInfo = Get-Content -Path $infoFile | ConvertFrom-Json
} else {
	$octoPrintInfo = [OctoPrintInfo]::New()
	Write-Host "No cached OctoPrint information found."
	if (!$serverAddress) {
		Write-Host "What is your local OctoPrint network name/address (e.g. 'octopi.local', '192.168.1.123')?"
		$octoPrintInfo.address = Read-Host -Prompt "    "
	} else {
		$octoPrintInfo.address = $serverAddress
	}
	if (!$octoPrintInfo.address.StartsWith("http")) {
		$octoPrintInfo.address = "http://" + $octoPrintInfo.address
	}
	if (!$apiKey) {
		Write-Host "Please provide a valid OctoPrint API key."
		$octoPrintInfo.apiKey = Read-Host -Prompt "    "
	} else {
		$octoPrintInfo.apiKey = $apiKey
	}
	Write-Host "Using address: $($octoPrintInfo.address)"
	Write-Host "    $($octoPrintInfo.address)" -ForegroundColor Green
	Write-Host "Using API key: $($octoPrintInfo.apiKey)"
	Write-Host "    $($octoPrintInfo.apiKey)" -ForegroundColor Green

	Write-Host "Testing API..."

	$testResult = Invoke-OctoPrintApi "version" "GET" $null $octoPrintInfo $cacheFolder $debugApi

	Write-Host "API test passed! OctoPrint version: $($testResult.text)" -ForegroundColor Green

	if (!$nocache) {
		Write-Host "Thanks! Your info is saved in the local cache here:"
		Write-Host "    $infoFile" -ForegroundColor Green
		Write-Host "This info will be used for future calls until you clear it, which"
		Write-Host "you can safely do by deleting the entire cache folder found here:"
		Write-Host "    $cacheFolder" -ForegroundColor Green
		$octoPrintInfo | ConvertTo-Json | Out-File -FilePath $infoFile
	}
}

Invoke-OctoPrintApi $operation $method $payload $octoPrintInfo $cacheFolder $debugApi

# Write-Host "Result"
# Write-Output $response.Content | ConvertFrom-Json