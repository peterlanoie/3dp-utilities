
class LineActionArgs {
	[int] $lineNumber
	[int] $layerNumber
	[bool] $isNewLayer
	[string] $lineText
}

# function Invoke-ForEachLine {
# 	param (
# 		[string[]] $lines,
# 		[System.Action[LineActionArgs]] $lineAction
# 	)

# 	$lineCount = $lines.Count
# 	$actionArgs = New-Object -TypeName LineActionArgs

# 	for ($i = 0; $i -lt $lineCount ; $i++) {
# 		$actionArgs.lineNumber = $i
# 		$actionArgs.isNewLayer = $false
# 		Write-Progress -Activity "Processing GCode lines" -PercentComplete ($i / $lineCount * 100)
# 		$actionArgs.lineText = $line = $lines[$i]
# #		$lineNumStr = ([string]$newLineCount).PadLeft(6, " ") + ":"

# 		if ($line.StartsWith(";LAYER:")) {
# 			$actionArgs.layerNumber = [int]$line.Replace(";LAYER:", "") + 1
# 			Write-Host "[$i] Found start of layer $($actionArgs.layerNumber)"
# 			$actionArgs.isNewLayer = $true
# 		}

# 		$lineAction.Invoke([LineActionArgs]$actionArgs)
# 	}
# }

function Update-File {
	param (
		[string] $infile,
		[string] $outFileSuffix,
		[bool] $overwrite,
		[System.Func[LineActionArgs, String[]]] $updateAction
	)
	$ErrorActionPreference = 'Stop'
	Write-Host "==========================================================="
	Write-Host "Processing file: $infile"
	Write-Host "-----------------------------------------------------------"

	if ($infile -is [String]) {
		$infile = Get-ChildItem $infile
	}
	
	if (-not (Test-Path -Path $infile)) {
		Write-Error "Input file path doesn't exist."
		return
	}

	$fileext = Split-Path -Path $infile -Extension
	
	if ($fileext -ne ".gcode") {
		Write-Error "Input file isn't GCODE, can't modify it: $infile"
		return
	}
	Write-Verbose "Out file suffix: $outFileSuffix"
	$outFileName = Split-Path -Path $infile -LeafBase
	$outFileName += "-$outFileSuffix.gcode"

	$filebase = Split-Path -Path $infile
	$outFileName = Join-Path -Path $filebase -ChildPath $outFileName
	
	if (-not $overwrite -and (Test-Path $outFileName)) {
		throw "Target file '$outFileName' already exists."
	}
	
	Write-Host "Generating new file: $outFileName"
	
	[string[]]$filelines = Get-Content $infile
	$newLines = [System.Text.StringBuilder]::new()

	$lineCount = $filelines.Count
	$actionArgs = New-Object -TypeName LineActionArgs

	for ($i = 0; $i -lt $lineCount ; $i++) {
		$actionArgs.lineNumber = $i
		$actionArgs.isNewLayer = $false
		Write-Progress -Activity "Processing GCode lines" -PercentComplete ($i / $lineCount * 100)
		$actionArgs.lineText = $line = $filelines[$i]

		if ($line.StartsWith(";LAYER:")) {
			$actionArgs.layerNumber = [int]$line.Replace(";LAYER:", "") + 1
			Write-Host "[$i] Found start of layer $($actionArgs.layerNumber)"
			$actionArgs.isNewLayer = $true
		}
		$resultLines = 	$updateAction.Invoke([LineActionArgs]$actionArgs) #
		if ($resultLines) {
			$resultLines | ForEach-Object { $newLines.AppendLine($_) | Out-Null }
		}
	}
	
	Set-Content -Path $outFileName -Value $newLines
}