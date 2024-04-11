
include <BOSL2/std.scad>
include <object_common_functions.scad>
include <attachable_text3d.scad>
include <logging.scad>

LOG_LEVEL = 2;


function _defined(a) = (is_list(a)) ? len(a) > 0 : !is_undef(a);
function _first(list) = [for (i = list) if (_defined(i)) i][0];
function _defined_len(list) = len([ for (i=list) if (_defined(i)) i]);

/// Function: _first_nonzero()
/// Synopsis: Carryover from 507common's `first_nonzero()`
/// Description:
///   Given a list of numerical elements, return the first defined, non-zero element in the list.
///   NB: non-zero really does mean non-zero; a list of `[0, -1, 1]` will yield `-1`.
function _first_nonzero(list) = [for (i = list) if (is_num(i) && i != 0) i][0];

/// Function: _defined_and_nonzero()
/// Synopsis: Carryover from 507common's `defined_and_nonzero()`
/// Description:
///   Returns true if argument `a` is defined and is not `0` (zero).
///   NB: non-zero really does mean non-zero; comparing `-1` will yield `true`.
function _defined_and_nonzero(a) = _defined(a) && a != 0;

