# 3D Printer Utilities

This repo is a collection of 3D printing utilities.

***Unless stated otherwise***
- ***anything here that adds Gcode or sends printer commands, does so using Marlin flavored commands.***
- ***anything here that controls the printer does so through OctoPrint's web API.***

## Printer control/adjustment
These use OctoPrint. You'll need to have a valid API key the first time you use of of these scripts. The key and OctoPrint URL will be saved locally for you.

- [Bed Leveling Mesh Adjuster](scripts/bedLeveling/README.md) - Utility to help manually adjust the auto bed leveling mesh through OctoPrint.
- [Flow and Feed rates adjuster](adjust-flow-fee-rates.ps1) - helper to adjust the feed and flow rates of an active print with arrow keys instead of having to use the printer's UI.

## Gcode modifiers

- [Misc Gcode modification scripts](scripts/gcode/README.md)