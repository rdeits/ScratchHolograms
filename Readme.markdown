About:
=============
This is a program designed to make it easier to create scratch holograms (see
http://www.eskimo.com/~billb/amateur/holo1.html). It allows the user to create a
3D model in Google SketchUp, and then convert that model into a pattern to
generate a hologram of the model. 

Requirements:
=============
python 2.6 or 2.7 with Matplotlib and Numpy
Google SketchUp (tested on version 8)

Installation:
=============
Currently, this is only tested on OS X 10.6 and 10.7. It can probably be made to
work on other systems relatively easily, but I haven't done so yet. 

Install SDXF from http://www.kellbot.com/sdxf-python-library-for-dxf/

Open up solid_pattern.rb: change the value of SCRIPTS_DIR to point to the
directory containing draw_pattern.py, and change PYTHON_PATH to point to your
python executable. Next, copy (or symlink) solid_pattern.rb to your Google
Sketchup Plugins folder (/Library/Application\ Support/Google\ SketchUp\
8/SketchUp/plugins/ on OS X). 

Usage:
=============
Create a new model in SketchUp (or open up one of the samples provided with
this distribution), and save it somewhere convenient. Then click Plugins ->
Make Solid Scratch Pattern... and save the *.pattern file in whatever folder
you want the pattern files to appear in. Shortly thereafter, the printable
pattern file (.pdf), the drawing file for CNC milling (.dxf), and simulated
views at two viewing angles (_view_+5.pdf, etc.) will appear in the same
folder. 

A few notes on usage:
The X and Y coordinates of the generated hologram correspond to the Y and Z
axes, respectively, of the SketchUp model, and the depth of the hologram
corresponds to the X axis of the model. A SketchUp model which is entirely in
the X<0 region will form a hologram below the surface of the material, while a
model in the X>0 region will form a hologram above the surface. 
