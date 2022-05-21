$cacheFolder = "$PSScriptRoot/.cache"
$infoFile = "$cacheFolder/octoprintData.json"

class OctoPrintInfo {
	[string] $address
	[string] $apiKey
}

$Verbose = $false
if ($PSBoundParameters.ContainsKey('Verbose')) { # Command line specifies -Verbose[:$false]
    $Verbose = $PsBoundParameters.Get_Item('Verbose')
}