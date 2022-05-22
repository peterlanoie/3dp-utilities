[CmdletBinding()]
param (
	# input file(s)
	[Parameter(ValueFromPipeline = $true, Mandatory = $true)]$infile,

	# whether to overwrite existing output files
	[Switch]$overwrite
)

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

	if ($infile.Name.EndsWith("-nocool.gcode")) {
		Write-Warning "File appears to be nocool already, skipping: $infile"
		return
	}

	$nocoolfile = Split-Path -Path $infile -LeafBase
	$filebase = Split-Path -Path $infile

	$nocoolfile = "$nocoolfile-nocool.gcode"
	$nocoolfile = Join-Path -Path $filebase -ChildPath $nocoolfile

	if (-not $overwrite -and (Test-Path $nocoolfile)) {
		throw "Target file '$nocoolfile' already exists."
	}

	Write-Host "Generating new file: $nocoolfile"

	[string[]]$filelines = Get-Content $infile
	$newLines = [System.Text.StringBuilder]::new()

	#M107 - fan off
	#M106 - fan set speed
	$foundM107 = $false
	$lineCount = $filelines.Count

	for ($i = 0; $i -lt $lineCount ; $i++) {
		Write-Progress -Activity "Processing GCode lines" -PercentComplete ($i / $lineCount * 100)
		$line = $filelines[$i]
		if ($line.StartsWith("M107") -or $line.StartsWith("M106")) {
			Write-Host "Found fan instruction at line $i : $line"
			$foundM107 = $true
		}
		if ($line.StartsWith("M106")) {
			Write-Host "	stripping instruction"
		}
		else {
			$newLines.AppendLine($line) | Out-Null
		}
	}

	if (-not $foundM107) {
		Write-Warning "No 'Fan Off' instruction found."
	}
	Set-Content -Path $nocoolfile -Value $newLines

	# } else {
	# 	Write-Error "$infile isn't a file"
	# }

}