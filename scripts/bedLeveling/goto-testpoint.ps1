[CmdletBinding()]
param (
	[Parameter(Position=0)]
	[int] $gridPointX,

	[Parameter(Position=1)]
	[int] $gridPointY,

	[Parameter(Position=2)]
	[double] $z = 0.2,

	[int] $bedMaxX = 235,
	[int] $bedMaxY = 235,

	[int] $testGridXpoints = 4,
	[int] $testGridYpoints = 4,

	[switch] $noecho
)

$xGridPoints = New-Object decimal[] $testGridXpoints
$yGridPoints = New-Object decimal[] $testGridYpoints

$gridPortionX = $bedMaxX / ($testGridXpoints - 1)
$gridPortionY = $bedMaxY / ($testGridYpoints - 1)

for ($i = 0; $i -lt $testGridXpoints; $i++) {
	$xGridPoints[$i] = [System.Math]::Round($i * $gridPortionX)
}

for ($i = 0; $i -lt $testGridYpoints; $i++) {
	$yGridPoints[$i] = [System.Math]::Round($i * $gridPortionY)
}

# $xGridPoints = @(0, 78, 156, 235)
# $yGridPoints = @(0, 78, 156, 235)

$x = $xGridPoints[$gridPointX];
$y = $yGridPoints[$gridPointY];

$travelHeight = $z + 1

$commands = "
G0 Z$travelHeight F6000
G0 X$x Y$y F6000
G0 Z$z F500"

."$PSScriptRoot\..\octoprint\send-commands.ps1" $commands -echo:(!$noecho) -noinfo