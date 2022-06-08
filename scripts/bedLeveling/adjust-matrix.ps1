[CmdletBinding()]
param (
	[int] $bedMaxX = 235,
	[int] $bedMaxY = 235,
	[decimal] $testZgap = 0.2,
	[switch] $speak, 
	[switch] $nohome
)

class Offset {
	[char] $Position
	[int] $X
	[int] $Y
	[decimal] $Offset
	[decimal] $AdjustedZ
	Offset($position, $x, $y, $adjustedZ){
		$this.Position = $position
		$this.X = $x
		$this.Y = $y
		$this.AdjustedZ = $adjustedZ
	}
}

[decimal]$jogDelta = 0.01

$testPoints = @(
	[Offset]::New('0', 0, 0, $testZgap),
	[Offset]::New('1', 0, 1, $testZgap),
	[Offset]::New('2', 0, 2, $testZgap),
	[Offset]::New('3', 0, 3, $testZgap),
	[Offset]::New('4', 1, 3, $testZgap),
	[Offset]::New('5', 1, 2, $testZgap),
	[Offset]::New('6', 1, 1, $testZgap),
	[Offset]::New('7', 1, 0, $testZgap),
	[Offset]::New('8', 2, 0, $testZgap),
	[Offset]::New('9', 2, 1, $testZgap),
	[Offset]::New('A', 2, 2, $testZgap),
	[Offset]::New('B', 2, 3, $testZgap),
	[Offset]::New('C', 3, 3, $testZgap),
	[Offset]::New('D', 3, 2, $testZgap),
	[Offset]::New('E', 3, 1, $testZgap),
	[Offset]::New('F', 3, 0, $testZgap)
)

function PrintHelp {
	Write-Host "###############################"
	Write-Host "##   Z adjustment routine.   ##"
	Write-Host "###############################"
	Write-Host "Z adjustment routine."
	Write-Host "Test point navigation:"
	Write-Host "  - Cycle through test points with [,] and [.] (e.g. [<] and [>] without the shift key)"
	Write-Host "  - Go direct to test points using the following keys:"
	Write-Host "     ------ rear ------"
	Write-Host "     [3]  [4]  [B]  [C]"
	Write-Host "     [2]  [5]  [A]  [D]"
	Write-Host "     [1]  [6]  [9]  [E]"
	Write-Host "     [0]  [7]  [8]  [F]"
	Write-Host "     ------ front -----"
	Write-Host "  - [X] to move to the bed center (typical homing location)"
	Write-Host ""
	Write-Host "Mesh adjustments:"
	Write-Host "  - [Up Arrow] to raise Z by 0.01mm"
	Write-Host "  - [Down Arrow] to lower Z by 0.01mm"
	Write-Host "  - [Enter] to send test point adjustment (mesh Z-delta) to printer"
	Write-Host "  - [R] to reset adjustment"
	Write-Host ""
	Write-Host "Test movements:"
	Write-Host "  - [T] goto bed center and back to current test point"
	Write-Host "  - [S] run test point circuit path"
	Write-Host ""
	Write-Host "Misc:"
	Write-Host "  - [M] to toggle speech mode"
	Write-Host "  - [H] print this help"
	Write-Host "  - Press Q or [ESC] to quit."
	Write-Host "###############################"
}

PrintHelp

$octoPrintPath = "$PSScriptRoot\..\octoprint"

$speechOn = $speak
$speechReady = $false

function Speak {
	param ($words)
	if($speechOn){
		if (!$speechReady) {
			$speaker = (New-Object -com SAPI.SpVoice)
			$speaker.rate = 5
		}
		$speaker.speak($words, 1) | Out-Null
	}
	return $words
}

function RunJog {
	param ([double] $zJog)

	$jogPayload = @{
		command = "jog"
		z = $zJog
	}
	
	."$octoPrintPath/call-api.ps1" -operation "printer/printhead" -method POST -payload $jogPayload
}

$testPointIndex = -1
$nextTestPointIndex = 0

if (!$nohome) {
	# First we gotta find home
	Write-Host "Homing printer"
	. "$octoPrintPath\send-commands.ps1" "G28 X Y Z" -noinfo
}
$running = $true
while($running){
	if ($nextTestPointIndex -ne $testPointIndex) {
		$currentTestPoint = $testPoints[($testPointIndex = $nextTestPointIndex)]
		Write-Host "Going to test point $($currentTestPoint.X) $($currentTestPoint.Y)"
		. "$PSScriptRoot\goto-testpoint.ps1" $currentTestPoint.X $currentTestPoint.Y $testZgap -noecho -bedMaxX $bedMaxX -bedMaxY $bedMaxY
		Speak("Test point $($currentTestPoint.X) $($currentTestPoint.Y)")
		$pointX = $currentTestPoint.X
		$pointY = $currentTestPoint.Y
	}

	$phrase = ""
	Write-Host "Current status:"
	Write-Host "   test point $($currentTestPoint.X) $($currentTestPoint.Y)"
	Write-Host "   adjustment: $($currentTestPoint.Offset)"
	Write-Host "   current Z: $($currentTestPoint.AdjustedZ)"
	Write-Host "   z jog delta: $jogDelta"
	$keyInput = [System.Console]::ReadKey($true) #$Host.UI.RawUI.ReadKey('NoEcho')
	$direction = 0
	switch ($keyInput.Key) {
		"RightArrow" {
			$jogDelta += 0.01
			$phrase = "increase z change step"
		}
		"LeftArrow" {
			if ($jogDelta -gt 0) {
				$jogDelta -= 0.01
				$phrase = "decrease z change step"
			}
		}
		"UpArrow" { 
			$direction = 1
			$phrase = "up"
		}
		"DownArrow" { 
			$direction = -1
			$phrase = "down"
		}
		"Enter" {
			[console]::beep(800,100)
			Write-Host (Speak("Saving new Z adjustment")) $currentTestPoint.Offset -ForegroundColor Green
#			$currentTestPoint.Offset = $zAdjustment
			$command = "M421 I$pointX J$pointY Q$($currentTestPoint.Offset)"
			. "$octoPrintPath\send-commands.ps1" -gcode $command
			$currentTestPoint.Offset = 0
			$currentTestPoint.AdjustedZ = $testZgap
			break
		}
		"Escape" {
			$running = $false
		}
	}
	switch -regex ($keyInput.KeyChar){
		"r" { 
			Write-Host "Resetting adjustment" -ForegroundColor Green
			RunJog($currentTestPoint.Offset * -1)
			$currentTestPoint.Offset = 0
			$currentTestPoint.AdjustedZ = $testZgap
			$phrase = "reset adjustment"
		}
		"q" {
			$running = $false
		}
		"m" {
			Write-Host (Speak("Speech is " + (($speechOn = !$speechOn) ? "on" : "off")))
		}
		"h" {
			PrintHelp
		}
		"[n\.]" {
			if ($testPointIndex -lt $testPoints.Length-1) {
				$nextTestPointIndex = $testPointIndex + 1
			} else {
				$nextTestPointIndex = 0 # cycle back to the beginning
			}
		}
		"[p,]" {
			if ($testPointIndex -gt 0) {
				$nextTestPointIndex = $testPointIndex - 1
			} else {
				$nextTestPointIndex = $testPoints.Length-1
			}
		}
		"t" {
			. "$octoPrintPath\goto.ps1" ($bedMaxX / 2) ($bedMaxY / 2) 10 6000
			. "$PSScriptRoot\goto-testpoint.ps1" $currentTestPoint.X $currentTestPoint.Y $testZgap -noecho -bedMaxX $bedMaxX -bedMaxY $bedMaxY
			Speak("Testing mesh point $($currentTestPoint.X) $($currentTestPoint.Y)")
		}
		"x" {
			. "$octoPrintPath\goto.ps1" ($bedMaxX / 2) ($bedMaxY / 2) 10 6000
			. "$octoPrintPath\goto.ps1" ($bedMaxX / 2) ($bedMaxY / 2) $testZgap 1500
			$nextTestPointIndex = $testPointIndex = -1
			Speak("Going to bed center")
		}
		"s" {
			Speak("Running mesh test point circuit")
			foreach ($circuitPoint in $testPoints) {
				$dwellSeconds = 2
				Write-Host "Going to test point: $($circuitPoint.X) $($circuitPoint.Y) with a $dwellSeconds second pause" -ForegroundColor Green
				. "$PSScriptRoot\goto-testpoint.ps1" $circuitPoint.X $circuitPoint.Y $testZgap -noecho -bedMaxX $bedMaxX -bedMaxY $bedMaxY
				. "$octoPrintPath\send-commands.ps1" "G4 S$dwellSeconds" -noinfo
				#Start-Sleep -Seconds 2
			}
			. "$PSScriptRoot\goto-testpoint.ps1" $currentTestPoint.X $currentTestPoint.Y $testZgap -noecho -bedMaxX $bedMaxX -bedMaxY $bedMaxY
		}
		'[0-9a-f]' {
			for ($i = 0; $i -lt $testPoints.Count; $i++) {
				if ($testPoints[$i].Position -eq $keyInput.KeyChar) {
					$nextTestPointIndex = $i
				}
			}
		}
	}
	if ($direction -ne 0) {
		$jog = $jogDelta * $direction
		$newAdjustment = $currentTestPoint.Offset + $jog
		if (($testZgap + $newAdjustment) -lt 0) {
			Write-Warning "Z is at 0, cannot adjust further"
			$newAdjustment = 0
		} else {
			Write-Host "Jogging Z by $jog" -ForegroundColor Green
			RunJog($jog)
			$currentTestPoint.Offset = $newAdjustment
			$currentTestPoint.AdjustedZ = $testZgap + $currentTestPoint.Offset
		}
	}
	
	if (!$running) {
		$phrase = "Have a nice day!"
		Write-Host "Quitting"
	}

	if ($phrase.Length -gt 0) {
		Speak($phrase) | Out-Null
	}
	#	Write-Host $direction
}

#$testPoints | Format-Table