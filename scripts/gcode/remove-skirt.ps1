[CmdletBinding()]
param (
	# input file(s)
	[Parameter(ValueFromPipeline = $true, Mandatory = $true)]$infile,

	# whether to overwrite existing output files
	[switch]$overwrite
)

Process {

	."$PSScriptRoot\.functions.ps1"

	$skirtCount = 0
	$inSkirt = $false
	$lastExtruderValue = 0

	$prescanAction = {
		param ($line)

		if ($line.startsWith(";TYPE:SKIRT")) {
			$script:skirtCount++
			Write-Host "skirts: $($script:skirtCount)"
		}
	}

	$updateAction = {
		param ($actionArgs)
		
		if ($actionArgs.lineText.StartsWith(";TYPE:SKIRT")) {
			Write-Host "Found skirt"
			$script:inSkirt = $true
			return @($actionArgs.lineText)
		}
		elseif ($script:inSkirt -and $actionArgs.lineText.StartsWith(";MESH")) {
			Write-Host "Found mesh after skirt, adding E axis reset"
			$script:inSkirt = $false
			return @(
				";Reset extruder to last motion's position",
				"G92 E$lastExtruderValue",
				$actionArgs.lineText
			)
		}
		elseif ($script:inSkirt) {
			if ($actionArgs.lineText.StartsWith("G1") -or $actionArgs.lineText.StartsWith("G0")) {
				$indexOfExtruder = $actionArgs.lineText.IndexOf(" E")
				if ($indexOfExtruder -gt 0) {
					$script:lastExtruderValue = $actionArgs.lineText.SubString($indexOfExtruder + 2)
					Write-Debug "New extruder value: $script:lastExtruderValue"
				}
				# return line commented
				return @(";" + $actionArgs.lineText)
			}
			else {
				return @($actionArgs.lineText)
			}
		}
		else {
			return $actionArgs.lineText
		}
	}

	Update-File $infile "noSkirt" $overwrite $updateAction $prescanAction
}
