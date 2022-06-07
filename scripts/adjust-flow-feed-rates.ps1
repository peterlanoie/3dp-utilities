[CmdletBinding()]
param (
	[int] $startFlowRate = 100,
	[int] $startFeedRate = 100
)

$flowRate = $newFlowRate = $startFlowRate
$feedRate = $newFeedRate = $startFeedRate

function Write-Help {
	Write-Host "Incremental flow adjustment routine."
	Write-Host "  - Feed Rate"
	Write-Host "    - [F] To set current feedrate"
	Write-Host "    - ► [Right Arrow] increase feedrate by 1%"
	Write-Host "    - ◄ [Left Arrow] decrease feedrate by 1%"
	Write-Host "    - [SHIFT]+[F] Reset to initial feedrate ($startFeedRate%)"
	Write-Host "  - Flow Rate"
	Write-Host "    - [E] To set current flowrate"
	Write-Host "    - ▲ [Up Arrow] increase flowrate by 1%"
	Write-Host "    - ▼ [Down Arrow] decrease flowrate by 1%"
	Write-Host "    - [SHIFT]+[E] Reset to initial flowrate ($startFlowRate%)"
	Write-Host "  - [H] - Write out this help text again"
	Write-Host "  - [Q]/[ESC] - Quit"
}

Write-Help
$running = $true
while($running){
	Write-Host "Current flow rate (▲ ▼): $flowRate%"
	Write-Host "Current feed rate (◄ ►): $feedRate%"
	$keyInput = [System.Console]::ReadKey($true)
	$feedDirection = $flowDirection = 0
	if ($keyInput.Modifiers -eq "Shift") {
		switch -regex ($keyInput.KeyChar){
			"z" {
				Write-Host "Resetting flow rate to original: $startFlowRate"
				$newFlowRate = $startFlowRate
			}
			"f" {
				Write-Host "Resetting feed rate to original: $startFeedRate"
				$newFeedRate = $startFeedRate
			}
		}
	} else {
		switch ($keyInput.Key) {
			"UpArrow" { 
				$flowDirection = 1
			}
			"DownArrow" { 
				$flowDirection = -1
			}
			"RightArrow" {
				$feedDirection = 1
			}
			"LeftArrow" {
				$feedDirection = -1
			}
			"Escape" {
				$running = $false
			}
		}
		switch -regex ($keyInput.KeyChar){
			"e" {
				$flowRate = $newFlowRate = [int](Read-Host -Prompt "Enter current flow rate")
			}
			"f" {
				$feedRate = $newFeedRate = [int](Read-Host -Prompt "Enter current feed rate")
			}
			"h" {
				Write-Help
			}
			"q" {
				$running = $false
			}
		}
	}
	if ($flowDirection -ne 0) {
		$newFlowRate = $flowRate + ($flowDirection * 1)
	}
	if ($feedDirection -ne 0) {
		$newFeedRate = $feedRate + ($feedDirection * 1)
	}
	if ($newFlowRate -ne $flowRate) {
		$flowRate = $newFlowRate
		Write-Host "Setting new flow rate: $flowRate%"
		$command = "M221 S$flowRate"
		. "$PSScriptRoot\octoprint\send-commands.ps1" -gcode $command -noinfo
	}
	if ($newFeedRate -ne $feedRate) {
		$feedRate = $newFeedRate
		Write-Host "Setting new feed rate: $feedRate%"
		$command = "M220 S$feedRate"
		. "$PSScriptRoot\octoprint\send-commands.ps1" -gcode $command -noinfo
	}
}
