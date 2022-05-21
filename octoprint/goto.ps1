[CmdletBinding()]
param (
	[Parameter(Position=0)]
	[decimal] $x,

	[Parameter(Position=1)]
	[decimal] $y,

	[Parameter(Position=2)]
	[decimal] $z,

	[Parameter(Position=3)]
	[decimal] $rate = 6000,

	[switch] $noecho
)

$commands = "G0 X$x Y $y Z$z F$rate"

."$PSScriptRoot\send-commands.ps1" $commands -echo:(!$noecho) -noinfo