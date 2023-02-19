[CmdletBinding()]
param (
	# input file(s)
	[Parameter(ValueFromPipeline = $true, Mandatory = $true)]$infile,

	[int] $startFeedPercent = 100,

	[int] $endFeedPercent = 100,

	[int] $startLayer = 1,

	[int] $feedIncrement = 0,

	# whether to overwrite existing output files
	[switch]$overwrite,

	[switch]$beepchange, 

	[switch]$beepdone
)

Process {

	."$PSScriptRoot\.functions.ps1"

	$adjustedLayers = $endLayer - $startLayer
	$flowDecrement = ($startFlowPercent - $endFlowPercent) / $adjustedLayers

	Write-Host = " Start layer number: $startLayer"
	Write-Host = " Start feed percent: $startFeedPercent"
	Write-Host = "   End feed percent: $endFeedPercent"
	Write-Host = "     Feed increment: $feedIncrement"

	$currentFeedPercent = $startFeedPercent

	$updateAction = {
		param ($actionArgs)
		
		if ($actionArgs.isNewLayer -and $actionArgs.layerNumber -ge $startLayer -and $currentFeedPercent -lt $endFeedPercent) {
			# This check ensure we can REPEAT this start to work with "One at a time" slicings
			# if ($actionArgs.isNewLayer -and $actionArgs.layerNumber -eq $startLayer) {
			# 	$script:actionIndex = 0
			# }
			$script:currentFeedPercent += $feedIncrement
			Write-Host "New feed rate %: $currentFeedPercent at layer $($actionArgs.layerNumber)"
			# $script:actionIndex++
			if($beepdone -and $currentFeedPercent -ge $endFeedPercent){
				$beep = "M300 S500"
			} elseif($beepchange){
				$beep = "M300 S50"
			}

			return @(
				$actionArgs.lineText,
				"M220 S$currentFeedPercent",
				$beep
			)
		} else {
			return $actionArgs.lineText
		}
	}

	Update-File $infile "incrementedFeed" $overwrite $updateAction
}
