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


