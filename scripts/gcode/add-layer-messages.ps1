[CmdletBinding()]
param (
	# input file(s)
	[Parameter(ValueFromPipeline = $true, Mandatory = $true)]$infile,

	# whether to overwrite existing output file
	[Switch]$force,

	# whether to replace the input file with the result
	[Switch]$replaceFile,

	# The suffix to append to the output file, ignored if $replace=true
	[string]$suffix = "-msg"
)

Begin {
	function get-timelabel {
		Param([int]$seconds)
	
		$timeSpan = New-TimeSpan -Seconds ($seconds)
		$eta = ""
		if ($timeSpan.Day -gt 0) {
			$eta += [string]$timeSpan.Day + "d"
		}
		if ($timeSpan.Hours -gt 0) {
			$eta += [string]$timeSpan.Hours + "h"
		}
		if ($timeSpan.Minutes -gt 0) {
			$eta += [string]$timeSpan.Minutes + "m"
		}
		if ($timeSpan.Seconds -gt 0) {
			$eta += [string]$timeSpan.Seconds + "s"
		}
		return $eta
	}
}

Process {
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

	if ($infile.Name.EndsWith("$suffix.gcode")) {
		Write-Warning "Input file has output suffix, skipping: $infile"
		return
	}

	if ($replaceFile) {
		$outfile = $infile
	} else {
		$outfile = Split-Path -Path $infile -LeafBase
		$filebase = Split-Path -Path $infile
	
		$outfile = "$outfile" + "$suffix.gcode"
		$outfile = Join-Path -Path $filebase -ChildPath $outfile
	
		if (-not $force -and (Test-Path $outfile)) {
			Write-Error "Target file '$outfile' already exists."
			return -1
		}
	}


	Write-Host "Output file: $outfile"
	Write-Host "Loading input file: $infile"
	[string[]]$filelines = Get-Content $infile
	$newLines = [System.Text.StringBuilder]::new()

	#;LAYER_COUNT:30
	#;LAYER:0
	#M117 Layer 1 of 30 single-x1
	#;TIME:6611
	#;TIME_ELAPSED:918.358486

	$lineCount = $filelines.Count
	$layerCount = 0
	$lastIsLayerComment = $false
	$currentLayer = 0
	$newLineCount = 0
	$eta = ""
	$layerMsgs = 0

	for ($i = 0; $i -lt $lineCount ; $i++) {
		$newLineCount++
		Write-Progress -Activity "Processing $infile" -Status "Updating GCode lines" -PercentComplete ($i / $lineCount * 100)
		$line = $filelines[$i]
		$lineNum = ([string]$newLineCount).PadLeft(6, " ") + ":"

		if ($line.StartsWith(";TIME:")) {
			$totalSeconds = [int]$line.Substring(6)
			Write-Host "$lineNum found total time: $totalSeconds"
			$eta = get-timelabel($totalSeconds)
			$totalTimeLabel = $eta
			$newLines.AppendLine($line) | Out-Null
			continue;
		}

		if ($line.StartsWith(";TIME_ELAPSED:")) {
			$elapsedSec = [int]$line.Substring(14)
			#			Write-Host "$lineNum elapsed time: $elapsedSec"
			$eta = get-timelabel($totalSeconds - $elapsedSec)
			$newLines.AppendLine($line) | Out-Null
			continue;
		}
		
		if ($line.StartsWith(";LAYER_COUNT")) {
			# Found total layer counter
			$layerCount = [int]$line.Substring(13)
			Write-Host "$lineNum found layer count: $layerCount"
			$newLines.AppendLine($line) | Out-Null
			continue;
		}

		if ($line.StartsWith(";LAYER:")) {
			$currentLayer = [int]$line.Substring(7)
			#			Write-Host "$lineNum found layer comment: $line"
			$lastIsLayerComment = $true
			$newLines.AppendLine($line) | Out-Null
		}
		else {
			if ($lastIsLayerComment) {
				$newInstruction = "M117 L-$($layerCount - $currentLayer)/$layerCount T-$eta/$totalTimeLabel"
				if ($line.Contains("M117")) {
					Write-Verbose "$lineNum updating existing message '$line' to '$newInstruction'"
					$newLines.AppendLine($newInstruction) | Out-Null
				}
				else {
					Write-Verbose "$lineNum adding message: $newInstruction"
					$newLines.AppendLine($newInstruction) | Out-Null
					$newLines.AppendLine($line) | Out-Null
					$newLineCount++
				}
				$layerMsgs++
				$lastIsLayerComment = $false
			}
			else {
				$newLines.AppendLine($line) | Out-Null
			}
		}
	}
	Write-Host "$layerMsgs layer messages added or updated."
	Write-Host "Saving output to $outfile"
	Set-Content -Path $outfile -Value $newLines
}
