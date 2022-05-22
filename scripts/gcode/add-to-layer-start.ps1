[CmdletBinding()]
param (
	# input file(s)
	[Parameter(ValueFromPipeline = $true, Mandatory = $true)]$infile,

	[string] $outFileName,

	[Parameter(Mandatory = $true)]
	[string] $newLine,

	[int] $minLayer = 1,

	[int] $maxLayer = 0,

	[string] $outFileSuffix = "modified",

	# whether to overwrite existing output files
	[switch]$overwrite
)

Process {

	."$PSScriptRoot\.functions.ps1"

	$updateAction = {
		param ($actionArgs)
		
		if ($actionArgs.isNewLayer -and $actionArgs.layerNumber -ge $minLayer -and ($maxLayer -eq 0 -or ($maxLayer -gt 0 -and $actionArgs.layerNumber -le $maxLayer))) {
			Write-Host "Adding line to Gcode: $newLine"
			return @(
				$actionArgs.lineText,
				$newLine
			)
		} else {
			return $actionArgs.lineText
		}
	}

	Update-File $infile $outFileSuffix $overwrite $updateAction
}