<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

This project generates an animated VGA pattern made of concentric rings. The
`hvsync_generator` module creates the 640x480 timing signals. The main module
calculates an approximate distance from the screen centre and uses that value
to select the RGB colour of each pixel.

`ui_in[0]` selects the animation speed. `ui_in[1]` selects whether the rings
move outward or inward. The eight dedicated outputs are RGB222 colour data plus
horizontal and vertical sync for the Tiny VGA PMOD.

## How to test

Connect the eight `uo_out` signals to a Tiny VGA PMOD or use the VGA Playground
simulator. Set `ui_in[0]` low for slow animation or high for fast animation.
Set `ui_in[1]` low for outward motion or high for inward motion. The design is
clocked at 25 MHz.

## External hardware

Tiny VGA PMOD or an equivalent RGB222 VGA interface and monitor.
