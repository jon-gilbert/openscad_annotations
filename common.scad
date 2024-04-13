/// LibFile: common.scad
///   Common include file across openscad_annotations LibFiles
///
/// Includes:
///   include <openscad_annotations/common.scad>
///

include <BOSL2/std.scad>
include <object_common_functions.scad>
include <attachable_text3d.scad>
include <logging.scad>

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



/// Function: multi_bw_xor()
/// Usage:
///   list = multi_bw_xor(bins);
/// Description:
///   Given a list of one or more btyes `bins`, 
///   XOR each with the next in the list, returning 
///   a single XOR'd byte as a list `list`. 
/// Example:
///   l = multi_bw_xor([[0, 1, 1, 1, 1, 0, 0, 1], [0, 1, 1, 0, 0, 1, 0, 1], [0, 1, 1, 0, 0, 1, 0, 1], [0, 1, 1, 1, 0, 1, 0, 0]]);
///   // l == [0, 0, 0, 0, 1, 1, 0, 1]
function multi_bw_xor(bins) = 
    let(
        r = (len(bins) >= 2)
            ? multi_bw_xor(select(bins, 1, -1))
            : bins[1]
    ) (len(bins) < 2) ? bins[0] : bitwise_xor(bins[0], r);


/// Function: str2bin()
/// Usage: 
///   list = str2bin(s);
/// Description:
///   Given a character string `s`, return its 
///   binary represetation as list of bits `list`.
/// Example:
///   l = str2bin("yeet");
///   // l == [[0, 1, 1, 1, 1, 0, 0, 1], [0, 1, 1, 0, 0, 1, 0, 1], [0, 1, 1, 0, 0, 1, 0, 1], [0, 1, 1, 1, 0, 1, 0, 0]]
function str2bin(s) = [for (i=s) ascii2bin(i)];


/// Function: dec2bin()
/// Usage:
///   list = dec2bin(d);
/// Description:
///   Given a decimal value `d`, convert that value 
///   to its binary representation, and return it  
///   as binary elements in a list `list`. 
/// Example:
///   l = dec2bin(2);
///   // l == [[0, 0, 0, 0, 0, 0, 1, 0]
/// Example:
///   l = dec2bin(127)
///   // l == [0, 1, 1, 1, 1, 1, 1, 1]
function dec2bin(d) = 
    let(
        bin = _dec2bin_rec(d),
        b = (len(bin) < 8)
            ? reverse(list_pad(reverse(bin), 8, 0))
            : bin
    ) b;

function _dec2bin_rec(d) =
    let(
        q = floor(d / 2),
        r = d - (q * 2),
        accum = (q > 0) ? _dec2bin_rec(q) : [],
        bin = list_insert(accum, len(accum), r)
    ) bin;


/// Function: ascii2bin()
/// Usage:
///   l = ascii2bin(c);
/// Description:
///   Given a string character `c`, return its 
///   binary representation as a list of bits `list`.
///   .
///   It is not an error to specify a multi-character 
///   string as `c`, but note that only the first 
///   character will be considered and have its 
///   binary represtation returned. 
/// Example:
///   l = ascii2bin("a");
///   // l == [0, 1, 1, 0, 0, 0, 0, 1]
function ascii2bin(c) = 
    let(
        _ = log_warning_if(len(c) > 1, 
            str("ascii2bin(): length of ", 
                c, 
                " is > 1, only the first char will be used"))
    ) dec2bin(ord(c[0]));


/// Function: bitwise_xor()
/// Usage:
///   list = bitwise_xor(a, b);
/// Description:
///   Given two lists of binary data `a`, `b`, perform 
///   an XOR of each positional bit in both lists, and 
///   return the result as a list `list`. 
///   .
///   It's an error to provide two lists that aren't 
///   the same dimensional size. 
/// Example:
///   l = bitwise_xor([0,0,1,0,1,1,0,1], [1,0,0,1,1,1,0,0]);
///   // l ==  [1, 0, 1, 1, 0, 0, 0, 1]
function bitwise_xor(a, b) = 
    assert(is_list(a))
    assert(is_list(b))
    [for (i=[0:len(a)-1]) a[i] == b[i] ? 0 : 1];


