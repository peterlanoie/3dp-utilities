# Gcode Modification Utilities

## `add-decremented-flow-rate.ps1`

This script will add a decrementing flow rate percentage modifier command (`M221`) to a defined number of layers, decreasing to 100%.

### Options & Usage

`add-decremented-flow-rate.ps1 -infile {filename} -startFlowPercent {percent}`

- `-infile` - file to modify (can also be used with a pipeline input for bulk operations)
- `-startFlowPercent` [int] - the starting flow rate percentage; default is `100`
- `-endFlowPercent` [int] - the ending flow percentage; default is `100`
- `-startLayer` [int] - the layer to start the flow rate modifications; default is `1`
- `-endLayer` [int] - the layer to end the flow rate modifications; default is `4`
- `-overwrite` [switch] - whether to overwrite existing output file(s)

The script will append `decrementedFlow` to the `infile` name(s).

Given the above defaults and a `startFlowPercent` of `125` and `endLayer` of 5, the layer flow rate modifications would be as follows:

- layer 1: 125%
- layer 2: 118.75%
- layer 3: 112.5%
- layer 4: 106.25%
- layer 5: 100%

### Reasoning

It is often convenient to be able to have different flow rates over several layers, possibly changing layer to layer. This is useful for printing methods such as "extreme vase mode" where you push the extruder to a larger line width than the nozzle diameter. A 2x line width in the slicer seldom yields a 2x wide line in the print. This is typically not a problem on the vase wall, but the first several layers end up with gaps. It's helpful to use an increased flow rate for the initial layers to ensure a complete surface.

While you can set material flow rates for various print elements (walls, infill, top, bottom), and you can set the initial layer flow, there's no way (at least when I wrote this) to set a varying flow rate over several layers. Also, setting flow rates in the slicer affects the overall extrusion calculation (factored into the Z axis distances) over the full scope of the Gcode. 

This script uses the flow rate percentage modifier to apply a layer by layer adjustment that's applied at print time by the firmware instead of affecting the overall slicer result. This allows for a bit more flexibility at print time.
