# openscad_annotations
Module and function libraries for annotating OpenSCAD models

These are library files originally developed for the 507 project. They provide modules and functions that wrap around and alongside OpenSCAD models which add elements of annotation around the models themselves. For example, measurementof of shape dimenions, or labeled flyouts detailing shape context that isn't available by visual inspection of the shape while it's in-scene. 

![](https://github.com/jon-gilbert/openscad_annotations/wiki/images/annotate/label.png)
![](https://github.com/jon-gilbert/openscad_annotations/wiki/images/bosl2_geometry/parent_geom_debug.png)
![](https://github.com/jon-gilbert/openscad_annotations/wiki/images/flyout/flyout_5.png)
![](https://github.com/jon-gilbert/openscad_annotations/wiki/images/mechanical/mechanical_3.png)
![](https://github.com/jon-gilbert/openscad_annotations/wiki/images/annotate/partno_2.png)
![](https://github.com/jon-gilbert/openscad_annotations/wiki/images/annotate/partno_attach_2.png)
![](https://github.com/jon-gilbert/openscad_annotations/wiki/images/mechanical/mechanical_11.png)
![](https://github.com/jon-gilbert/openscad_annotations/wiki/images/bosl2_geometry/parent_geom_debug_bounding_box.png)
![](https://github.com/jon-gilbert/openscad_annotations/wiki/images/annotate/annotate_fig1.png)
![](https://github.com/jon-gilbert/openscad_annotations/wiki/images/mechanical/mechanical_17.png)


# Installation
`openscad_annotations` is written and tested on OpenSCAD 2021.01, the most recent GA release of OpenSCAD. Visit https://openscad.org/ for installation instructions.

## Requried External Libraries

### BOSL2
You'll need the Belfry OpenSCAD Library (v.2). Authored by a number of contributors. Located at https://github.com/BelfrySCAD/BOSL2

To download this library, follow the instructions provided at https://github.com/BelfrySCAD/BOSL2#installation

## Other Libraries
You'll also need 
[openscad_objects](https://github.com/jon-gilbert/openscad_objects) ([direct library download](https://raw.githubusercontent.com/jon-gilbert/openscad_objects/main/object_common_functions.scad)), 
[openscad_attachable_text3d](https://github.com/jon-gilbert/openscad_attachable_text3d) ([direct](https://raw.githubusercontent.com/jon-gilbert/openscad_attachable_text3d/main/attachable_text3d.scad)), and
[openscad_logging](https://github.com/jon-gilbert/openscad_logging) ([direct](https://raw.githubusercontent.com/jon-gilbert/openscad_logging/main/logging.scad)).

## openscad_annotations
Download the most recent tagged release and download its compressed tgz or zip file, whichever you're more comfortable with. Uncompress and extract the folder within the release, which should be named something like `openscad_annoatations-0.0`. Rename that folder to `openscad_annotations`, and move that folder to the OpenSCAD library directory for your platform:

* Linux: $HOME/.local/share/OpenSCAD/libraries/
* Mac OS X: $HOME/Documents/OpenSCAD/libraries/
* Windows: My Documents\OpenSCAD\libraries\


# Author & License

This library is copyright 2023-2024 Jonathan Gilbert <jong@jong.org>, and released for use under the [MIT License](LICENSE.md).

