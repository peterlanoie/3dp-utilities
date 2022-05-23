[CmdletBinding()]
param (
	# input file(s)
	[Parameter(ValueFromPipeline = $true, Mandatory = $true)]$infile,

	[int] $startFlowPercent = 100,

	[int] $endFlowPercent = 100,

	[int] $startLayer = 1,

	[int] $endLayer = 4,

	# whether to overwrite existing output files
	[switch]$overwrite
)

Process {

	."$PSScriptRoot\.functions.ps1"

	$adjustedLayers = $endLayer - $startLayer
	$flowDecrement = ($startFlowPercent - $endFlowPercent) / $adjustedLayers

	Write-Host = " Start layer number: $startLayer"
	Write-Host = "   End layer number: $endLayer"
	Write-Host = " Start flow percent: $startFlowPercent"
	Write-Host = "   End flow percent: $endFlowPercent"
	Write-Host = "Flow rate decrement: $flowDecrement"

	$decrementIndex = 0
	$flowRates = New-Object decimal[] ($adjustedLayers + 1)
	for ($i = $startLayer; $i -le $endLayer; $i++) {
		$layerFlow = $endFlowPercent + ($flowDecrement * ($adjustedLayers - $decrementIndex))
		Write-Verbose "Layer $i flow rate: $layerFlow"
		$flowRates[$decrementIndex] = $layerFlow
		$decrementIndex++
	}

	$actionIndex = 0

	$updateAction = {
		param ($actionArgs)
		
		if ($actionArgs.isNewLayer -and $actionArgs.layerNumber -ge $startLayer -and $actionArgs.layerNumber -le $endLayer) {
			# Write-Verbose "Flow rates:"
			# $flowRates | Write-Verbose
			Write-Verbose "Decrement index: $actionIndex"
			$layerFlow = $flowRates[$actionIndex]
			Write-Verbose "New layer flow rate: $layerFlow"
			$script:actionIndex++
			Write-Host "Adding adjustment to $layerFlow%"
			return @(
				$actionArgs.lineText,
				"M221 S$layerFlow"
			)
		} else {
			return $actionArgs.lineText
		}
	}

	Update-File $infile "decrementedFlow" $overwrite $updateAction
}
