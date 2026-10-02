<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

This project implements a compact retro Snake game for a 640x480 VGA display.
The `hvsync_generator` module creates the VGA timing signals. The game uses a
40 by 30 logical grid, stores the snake as a short list of cell coordinates,
and draws the snake and food directly from the current pixel position without
using a framebuffer.

The snake grows when it reaches the red food, and the game ends when it hits a
wall or its own body. The eight dedicated outputs carry RGB222 colour data plus
horizontal and vertical sync for the Tiny VGA PMOD.

Inputs are `ui_in[0]` left, `ui_in[1]` right, `ui_in[2]` up, `ui_in[3]` down,
and `ui_in[4]` restart.

## How to test

Connect the eight `uo_out` signals to a Tiny VGA PMOD or use the VGA Playground
simulator. Drive one of the five control inputs to change direction or restart
the game. The design is clocked at 25.175 MHz.

## External hardware

Tiny VGA PMOD or an equivalent RGB222 VGA interface and monitor.
