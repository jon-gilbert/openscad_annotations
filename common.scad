/// LibFile: common.scad
///   Common include file across openscad_annotations LibFiles
///
/// Includes:
///   include <openscad_annotations/common.scad>
///

include <BOSL2/std.scad>
include <openscad_objects/objects.scad>
include <openscad_attachable_text3d/attachable_text3d.scad>
include <openscad_logging/logging.scad>

LOG_LEVEL = 2;


/// Function: _defined()
/// Synopsis: Carryover from 507common's `defined()`: test to see if a given variable is defined
/// Usage:
///   bool = _defined(value);
function _defined(a) = (is_list(a)) ? len(a) > 0 : !is_undef(a);


/// Function: _defined_len()
/// Synopsis: Carryover from 507common's `defined_len()`: return the number of defined elements in a list
/// Usage:
///   len = _defined_len(list);
function _defined_len(list) = len([ for (i=list) if (_defined(i)) i]);


/// Function: _defined_and_nonzero()
/// Synopsis: Carryover from 507common's `defined_and_nonzero()`: test to see if a given variable is defined and non-zero
/// Description:
///   Returns true if argument `a` is defined and is not `0` (zero).
///   NB: non-zero really does mean non-zero; comparing `-1` will yield `true`.
function _defined_and_nonzero(a) = _defined(a) && a != 0;


/// Function: _first()
/// Synopsis: Carryover from 507common's `first()`: return the first "defined" value in a list
/// Usage:
///   val = _first(list);
function _first(list) = [for (i = list) if (_defined(i)) i][0];


/// Function: _first_nonzero()
/// Synopsis: Carryover from 507common's `first_nonzero()`: return the first non-zero number in a list
/// Description:
///   Given a list of numerical elements, return the first defined, non-zero element in the list.
///   NB: non-zero really does mean non-zero; a list of `[0, -1, 1]` will yield `-1`.
function _first_nonzero(list) = [for (i = list) if (is_num(i) && i != 0) i][0];

/// Constant: RENDER_ANNOTATIONS
/// Description: 
///   Boolean specifying whether annotations should be present during 
///   rendering (as opposed to during preview). 
///   Currently: `false`
/// See Also: ok_to_annotate()
RENDER_ANNOTATIONS = false;

/// Constant: PREVIEW_ANNOTATIONS
/// Description: 
///   Boolean specifying whether annotations should be present during 
///   previews (as opposed to during a proper render). 
///   Currently: `true`
/// See Also: ok_to_annotate()
PREVIEW_ANNOTATIONS = true;

// Function&Module: ok_to_annotate()
// Synopsis: Determine if annotation should be done
// Usage: as a function:
//   bool = ok_to_annotate();
//   bool = ok_to_annotate(<force=false>);
// Usage: as a module:
//   ok_to_annotate() [CHILDREN];
//   ok_to_annotate(<force=false>) [CHILDREN];
//
// Description:
//   Simplification of whether or not to produce model annotations, flyouts, or measurements. 
//   .
//   As a function, `ok_to_annotate()` examines the setting of `$preview`, `PREVIEW_ANNOTATIONS`, & `RENDER_ANNOTATIONS`,  
//   and returns either `true` (meaning an annotation should be modeled) or `false` 
//   (meaning an annotation should not be modeled). An optional `force` boolean can be provided 
//   to indicate that no matter what `ok_to_annotate()` would have normally decided, 
//   annotation *is* OK; the default of `force` is `false`.
//   .
//   The selection of annotation behavior can be adjusted or overridden by individual SCAD models by 
//   changing `PREVIEW_ANNOTATIONS` from `true` to `false`, indicating that 
//   annotations should be not included during preview modes. This behavior is normally set to 
//   `true`, and annotations are normally modeled and displayed in preview mode.
//   .
//   This behavior can also be adjusted with the `RENDER_ANNOTATIONS` boolean, 
//   where setting it to `true` will cause annotations to be fully rendered and 
//   exported as STL or OBJ, or what-have-you; this is not the normal behavior.
//   .
//   As a module, `ok_to_annotate()` does the same as when invoked as a function, but instead 
//   of returning a boolean value, it processes all the child modules passed to it. 
//   The decision to process those children is exactly as if it were invoked as a function. 
//   In module form, `ok_to_annotate()` also accepts a `force` argument that will override 
//   whatever would have normally been decided. 
// 
// Arguments:
//   ---
//   force = Boolean that, if set to `true`, will ignore all other aspects and consider annotation to be OK. Default: `false`
//
// Continues:
//   `PREVIEW_ANNOTATIONS` is a setting that determines if annotations should be 
//   modeled when previewing models. Usually, and by default, this is enabled with `true`.
//   `RENDER_ANNOTATIONS` is a setting that determines if annotations should be modeled 
//   when fully rendered or not. Usually, and by default, this is disabled with `false`.
//   These two `PREVIEW_ANNOTATIONS` and `RENDER_ANNOTATIONS` variables exist 
//   to change this behavior from the command-line. You can set these to 
//   `true` or `false`, depending on what you need, and OpenSCAD will 
//   use them in conjuction with `ok_to_annotate()` when 
//   deciding if the block under the `if` should be produced. 
//
// Example(NORENDER): very basic usage of "should this block of modeling be executed?"
//   if (ok_to_annotate()) {
//     // this block will be modeled, if 
//     // if ok_to_annotate() returned true
//   }
//
// Example(NORENDER): setting `RENDER_ANNOTATIONS` to `true` on the command-line. Normally, `RENDER_ANNOTATIONS` is `false`.
//   $ openscad -D"RENDER_ANNOTATIONS=true"
//   // rendering these models will include annotations
//
function ok_to_annotate(force=false) = 
    let(
        show_preview = ($preview && PREVIEW_ANNOTATIONS), 
        show_render =  (!$preview && RENDER_ANNOTATIONS)
    )
    force || show_preview || show_render;


module ok_to_annotate(force=false) {
    req_children($children);
    if (ok_to_annotate(force))
        children();
}


