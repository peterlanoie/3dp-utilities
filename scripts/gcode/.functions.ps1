
class LineActionArgs {
	[int] $lineNumber
	[int] $layerNumber
	[bool] $isNewLayer
	[string] $lineText
}

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

	$startTime = Get-Date

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

	$tempOutFile = $outFileName + ".temp"
	if(Test-Path -Path $tempOutFile){
		Remove-Item -Path $tempOutFile -Force
	}
	
#	$fileSize = (Get-Item $infile).length
	$processedLength = 0
	$layerCount = 0
	$lineCount = 0

	$lineIterator = [System.IO.File]::ReadLines($infile)

	Write-Host "Doing file prescan..."
	foreach ($line in $lineIterator) {
		$lineCount++
		if ($line.StartsWith(";LAYER:")) {
			$layerCount++
		}
	}
	Write-Host "Found $layerCount layers in $lineCount lines"
#	$lineIterator.Reset()

	$actionArgs = New-Object -TypeName LineActionArgs

	$newLines = [System.Text.StringBuilder]::new()
	# $flushThreshold = 50 * 1024
	$i = 0
	foreach ($line in $lineIterator) {
		$actionArgs.lineNumber = $i++
		$actionArgs.isNewLayer = $false
		$actionArgs.lineText = $line # = $filelines[$i]
		$processedLength += $line.Length + 1
		Write-Progress -Activity "Processing GCode lines ($i)" -PercentComplete ($i / $lineCount * 100)

		if ($line.StartsWith(";LAYER:")) {
			$actionArgs.layerNumber = [int]$line.Replace(";LAYER:", "") + 1
			Write-Host "[$i] Found start of layer $($actionArgs.layerNumber)"
			$actionArgs.isNewLayer = $true
		}
		$resultLines = 	$updateAction.Invoke([LineActionArgs]$actionArgs) #
		#if ($resultLines) {
			$resultLines | ForEach-Object { $newLines.AppendLine($_) | Out-Null }
		#}
		# flush new line buffer every 10k chars

		# if ($newLines.Length -gt $flushThreshold) {
		# 	[System.IO.File]::AppendAllText($tempOutFile, $newLines)
		# 	$newLines.Clear() | Out-Null
		# }
	}
	#final flush
	[System.IO.File]::AppendAllText($tempOutFile, $newLines)

	Move-Item -Path $tempOutFile -Destination $outFileName -Force
#	Set-Content -Path $outFileName -Value $newLines

	$endTime = Get-Date
	$elapsedTime = $endTime - $startTime
	Write-Host "Process Time: $elapsedTime"
}