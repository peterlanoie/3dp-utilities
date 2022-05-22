[CmdletBinding()]
param (
	# input file(s)
	[Parameter(ValueFromPipeline = $true, Mandatory = $true)]$infile,

	[string] $outFileName,

	[int] $flowPercent = 125,

	[int] $minLayer = 1,

	[int] $maxLayer = 4,

	# whether to overwrite existing output files
	[switch]$overwrite
)

Process {

	."$PSScriptRoot\.functions.ps1"

	$updateAction = {
		param ($actionArgs)
		
		if ($actionArgs.isNewLayer -and $actionArgs.layerNumber -ge $minLayer -and ($maxLayer -eq 0 -or ($maxLayer -gt 0 -and $actionArgs.layerNumber -le $maxLayer))) {
			Write-Host "Adding adjustment to $flowPercent%"
			return @(
				$actionArgs.lineText,
				"M221 S$flowPercent"
			)
		} elseif ($actionArgs.isNewLayer -and $actionArgs.layerNumber -eq ($maxLayer + 1)) {
			Write-Host "Adding reset to 100%"
			return @(
				$actionArgs.lineText,
				"M221 S100"
			)
		} else {
			return $actionArgs.lineText
		}
	}

	Update-File $infile "highFlowStart" $overwrite $updateAction
}
