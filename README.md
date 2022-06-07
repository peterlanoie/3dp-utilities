# 3D Printer Utilities

This repo is a collection of 3D printing utilities.

So far, they are all in the form of Powershell scripts. I wrote them on a Windows machine, but tested in Powershell core, so in theory, they should work on powershell core on Linux (and presumably Macs).

***Unless stated otherwise***
- ***anything here that adds Gcode or sends printer commands, does so using Marlin flavored commands.***
- ***anything here that controls the printer does so through OctoPrint's web API.***

## Printer control/adjustment
These use OctoPrint. You'll need to have a valid API key the first time you use one of these scripts. The key and OctoPrint URL will be saved locally for you.

- [Bed Leveling Mesh Adjuster](scripts/bedLeveling/README.md) - Utility to help manually adjust the auto bed leveling mesh through OctoPrint.
Run: `scripts/bedLeveling/adjust-matrix.ps1`
- [Flow and Feed rates adjuster](scripts/adjust-flow-feed-rates.ps1) - helper to adjust the feed and flow rates of an active print with arrow keys instead of having to use the printer's UI.
Run: `scripts/adjust-flow-feed-rates.ps1`

## Gcode modifiers

- [Misc Gcode modification scripts](scripts/gcode/README.md)