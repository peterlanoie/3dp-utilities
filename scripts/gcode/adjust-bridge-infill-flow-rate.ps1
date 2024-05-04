[CmdletBinding()]
param (
	# input file(s)
	[Parameter(ValueFromPipeline = $true, Mandatory = $true)]$infile,

	[int] $bridgeFlowPercent = 100,

	[int] $bridgeFeedPercent = 100,

	[string] $bridgeStartIndicateText = ";TYPE:Bridge infill",

	[string] $bridgeEndIndicateText = ";TYPE:",

	# whether to overwrite existing output files
	[switch]$overwrite
)

Process {

	."$PSScriptRoot\.functions.ps1"


	

	class LineHandlerState {
		[LineHandlerState]$nextState = $this

		[String[]] ProcessLine($lineArgs) {
			return @($lineArgs.lineText)
		}

		[LineHandlerState] GetNextState() {
			return $this.nextState
		}
	}

	class OutsideBridgeInfillState : LineHandlerState {
		[String[]] ProcessLine($lineArgs) {
			if ($lineArgs.lineText.contains($script:bridgeStartIndicateText)) {
				Write-Host "Adjusting flow to $script:bridgeFlowPercent% and feed to $script:bridgeFeedPercent% at line $($lineArgs.lineNumber)"
				$this.nextState = [InsideBridgeInfillState]::new()
				return @(
					$lineArgs.lineText,
					"Adjusting bridge infill feed and flow rates",
					"M221 S$script:bridgeFlowPercent",
					"M220 S$script:bridgeFeedPercent"
				)
			}
			else {
				return @(
					$lineArgs.lineText
				)
			}
		}
	}

	class InsideBridgeInfillState : LineHandlerState {

		[String[]] ProcessLine($lineArgs) {
			if ($lineArgs.lineText.contains($script:bridgeEndIndicateText)) {
				Write-Host "Restoring flow to 100% and feed to 100% at line $($lineArgs.lineNumber)"
				$this.nextState = [OutsideBridgeInfillState]::new()
				return @(
					";Restoring bridge infill feed and flow rates"
					"M221 S100",
					"M220 S100",
					$lineArgs.lineText
				)
			}
			else {
				return @(
					$lineArgs.lineText
				)
			}
		}
	}

	Write-Host "Setting state machine to outside bridging"
	$currentState = [OutsideBridgeInfillState]::new()

	$updateAction = {
		param ([LineActionArgs] $actionArgs)

		$result = $script:currentState.ProcessLine($actionArgs)
		$script:currentState = $script:currentState.GetNextState()
		return $result
	}

	Update-File $infile "adjustedBridgeFlow" $overwrite $updateAction
}

