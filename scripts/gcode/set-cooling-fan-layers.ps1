[CmdletBinding()]
param (
	# input file(s)
	[Parameter(ValueFromPipeline = $true, Mandatory = $true)]$infile,

	[string] $outFileName,

	[int] $coolingPercent = 100,

	[int] $fullSpeedLayer = 5,

	# whether to overwrite existing output files
	[Switch]$overwrite
)

Process {
	Write-Host "==========================================================="
	Write-Host "Processing file: $infile"
	Write-Host "-----------------------------------------------------------"

	$coolingPercent = [System.Math]::Max([System.Math]::Min($coolingPercent, 100), 0)
	$fanIncrement = (256 * ($coolingPercent / 100)) / ($fullSpeedLayer - 1)

	Write-Host "Cooling percent: $coolingPercent"
	Write-Host "Full speed layer: $fullSpeedLayer"
	Write-Host "Per layer fan increment: $fanIncrement"

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
	
	# if ($infile.Name.EndsWith("-nocool.gcode")) {
	# 	Write-Warning "File appears to be nocool already, skipping: $infile"
	# 	return
	# }

	if (!$outFileName) {
		Write-Host "No outfile specified, creating default name."
		$outFileName = Split-Path -Path $infile -LeafBase
		$outFileName = $outFileName -replace "-[\d]{1,3}cf",""
		$outFileName = "$outFileName-$($coolingPercent)cf.gcode"
	}
	$filebase = Split-Path -Path $infile
	# $nocoolfile = "$nocoolfile-nocool.gcode"
	$outFileName = Join-Path -Path $filebase -ChildPath $outFileName
	
	if (-not $overwrite -and (Test-Path $outFileName)) {
		throw "Target file '$outFileName' already exists."
	}
	
	Write-Host "Generating new file: $outFileName"
	
	[string[]]$filelines = Get-Content $infile
	$newLines = [System.Text.StringBuilder]::new()
	
	$lineCount = $filelines.Count
	$setInitialOff = $false
	$readyToSetFan = $false
	$currentLayer = 0
	$fanOffFinal = $false
	
	for ($i = 0; $i -lt $lineCount ; $i++) {
		Write-Progress -Activity "Processing GCode lines" -PercentComplete ($i / $lineCount * 100)
		$line = $filelines[$i]

		if($line.StartsWith("M109 ") -and !$setInitialOff){
			$newLines.AppendLine("M107 ;Turn off cooling fan") | Out-Null
			$setInitialOff = $true
		}

		if ($line.StartsWith(";LAYER:")) {
			$currentLayer = [int]$line.Replace(";LAYER:", "")
			Write-Host "[$i] Found start of layer $($currentLayer + 1)"
			if(!$readyToSetFan){
				$readyToSetFan = $true
			}
		}
		
		if ($line.StartsWith("M106") -or $line.StartsWith("M107")) {
			Write-Host "Ignore existing fan command: $line"
			continue
		}
		
		if ($currentLayer -lt $fullSpeedLayer) {
			
			if ($readyToSetFan -and !$line.StartsWith(";")) {
				$fanSpeed = [System.Math]::Max([System.Math]::Round($currentLayer * ($fanIncrement)) - 1, 0)
				$newLines.AppendLine("M106 S$fanSpeed ;Set cooling fan speed") | Out-Null
				Write-Host "setting fan speed $fanSpeed"
				$readyToSetFan = $false
			}
		}

		if ($line.StartsWith("M104 S0") -and ($currentLayer -gt 0) -and !$fanOffFinal) {
			$newLines.AppendLine("M107 ;Turn off cooling fan") | Out-Null
			$fanOffFinal = $true
		}

		$newLines.AppendLine($line) | Out-Null

		# if ($line.StartsWith("M106")) {
		# 	Write-Host "	stripping instruction"
		# }
		# else {
		# 	$newLines.AppendLine($line) | Out-Null
		# }
	}
	
	Set-Content -Path $outFileName -Value $newLines

	$outFileName = $null
	# } else {
	# 	Write-Error "$infile isn't a file"
	# }

}