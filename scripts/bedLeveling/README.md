# Bed Leveling Mesh Adjuster

The `adjust-matrix.ps1` helper script is designed to help make manual adjustment to the auto bed leveling matrix.
It was designed originally for use on a Creality CR-6SE that suffers from some bed flex when the nozzle comes down on the bed to activate the touch sensor.

This script will allow you to travel to all the leveling mesh test points at a defined Z height, where you can then jog the Z height up and down in small increments until your height test (paper, thickness gauges, etc.) is satisfactory, then you can commit the delta in the Z height back to the printer as a mesh adjustment for that mesh point.

## Defaults 

Since it was designed for the Creality CR-6SE, this utility uses the following defaults:

- Bed dimensions: 235 x 235
- Leveling mesh: 16 test points

The testing Z height is 2.0 mm

## Startup Options and Switches

- `-bedMaxX` - provide the bed's X size
- `-bedMaxY` - provide the bed's Y size
- `-testZgap` - the Z height the head goes to at each mesh point (adjust this to your measurement device)
  - regular paper is ~1mm
  - heavy card stock is ~2mm


## Making adjustments

### Navigate test points

- use the `<` and `>` keys to cycle through the test points (previous, next)
- use dedicated keys (`0`-`9`,`A`,`B`,`C`,`D`,`E`,`F` for a 4x4 grid) to go direct to a test point

### Adjusting the Z mesh offset

- Jog Z - Use the `[UP]` and `[DOWN]` arrow keys to jog the Z height by the current increment.
- Change Z jog amount - Use `[LEFT]` and `[RIGHT]` arrow keys to increase the Z jog amount by 0.01mm (default is 0.01mm)
- Reset Z - Use `R` to reset the Z adjustment back to 0
- Save adjustment - `[ENTER]` saves the current Z adjustment delta to the mesh point

Leaving the current point after jogging Z without saving the adjustment will lose the adjustment. 
When you return to the test point it will be back at 0 delta.

## Testing Mesh Adjustment

### Test the current mesh point
Use the `T` key to translate the print head up and bit and to the center of the bed, then back to the test point. This helps to test that the mesh adjustment stuck properly.

### Run Test Circuit

Use the `S` key to run through all the mesh test points with a short delay between them so you can spot check the heights.

## Safeties

- You can't jog the head below 0mm Z height
- The script will issue a `G28` command to home the printer before translating to the first test point
  - This can be skipped with the `-nohome` switch on the script. **SKIP AT YOUR OWN RISK**

## Bonus Features

### Speech Mode

When run on Windows, hitting `M` will enable or mute the Windows speech API that reads out actions and locations as you move. You can enable this from script startup with the `-speak` switch.