// LibFile: bosl2_geometry.scad
//   Reinterpretaion & abstraction of BOSL2's `$parent_geom` list into an Object, and 
//   modules and functions to help debug parent geometries.
//
// Includes:
//   include <openscad_annotations/bosl2_geometry.scad>
//
/// Wow. So, I really didn't want to write this.

include <openscad_annotations/common.scad>
include <openscad_annotations/flyout.scad>


// Section: Geometry Debugging Modules
//
/// Constant: HIGHLIGHT_COLOR
HIGHLIGHT_COLOR = "OrangeRed";


// Module: parent_geom_debug()
// Synopsis: Display geometry debugging information
// Usage:
//   [ATTACHABLE] parent_geom_debug();
// Description:
//   Displays various geometry information surrounding an attachable parent.
// Arguments: `parent_geom_debug()` accepts no arguments.
// Todo:
//   currently uses `flyout_to_pos()` to the shape's centerpoint, but what if instead it was to the RIGHT+TOP edge of the shape?
// Example:
//   sphere(20)
//       parent_geom_debug();
//
module parent_geom_debug() {
    geom = Geom();
    thickness = 0.5;
    boundary = parent_geom_bounding_box();

    color(HIGHLIGHT_COLOR) {

        parent_geom_debug_axis(geom=geom, thickness=thickness);

        parent_geom_debug_bounding_box(geom=geom);

        if (geom_anchors(geom))
            parent_geom_debug_anchors(geom);

        if (geom_vnf(geom))
            vnf_wireframe(vnf, width=thickness);

        flyout_to_pos(geom_centerpoint(geom), leader=boundary.x/2, thickness=thickness, color=HIGHLIGHT_COLOR, alpha=1)
            attach("flyout-text", LEFT)
                attachable_text3d_multisize(
                    [
                        [[geom_type(geom)], 5],
                        [
                            list_remove_values([
                                str("Dimension boundary: ", boundary),
                                (_defined_and_nonzero(geom_radius1(geom)) || _defined_and_nonzero(geom_radius2(geom)))
                                    ? str("Radii: ", geom_radius1(geom), ", ", geom_radius2(geom, default="[none]")) : undef,
                                (_defined(geom_size(geom)))
                                    ? str("Sizes: ", geom_size(geom), ", ", geom_size2(geom, default="[none]")) : undef,
                                (geom_length(geom) > 0)
                                    ? str("Length: ", geom_length(geom)) : undef,
                                (_defined(geom_axis(geom)))
                                    ? str("Axis: ", geom_axis(geom)) : undef,
                                (_defined(geom_anchors(geom)) && len(geom_anchors(geom)) > 0)
                                    ? str("Anchors: ", len(geom_anchors(geom))) : undef,
                                (_defined(geom_shift(geom)))
                                    ? str("Shift: ", geom_shift(geom)) : undef,
                                (_defined(geom_offset(geom)))
                                    ? str("Offset: ", geom_offset(geom)) : undef,
                                (_defined(geom_vnf(geom)) || _defined(geom_region(geom)))
                                    ? str("Has a ", (_defined(geom_vnf(geom))) ? "VNF " : "", (_defined(geom_region(geom))) ? "region" : "") : undef,
                            ], [undef], all=true),
                            3
                        ],
                    ]);
    }
}


// Module: parent_geom_debug_axis()
// Synopsis: Display geometry axis information
// Usage:
//   parent_geom_debug_axis();
//   parent_geom_debug_axis(<geom=undef>, <thickness=0.5>);
// Description:
//   As a child module, display axis information for a shape's
//   geometry. The axis as pulled from the attachable shape, 
//   or from an optional geometry as passed as a `geom` 
//   argument, is shown as a dashed stroke. 
// Arguments:
//   geom = An instantiated Geom object. Default: `undef`, in which case the geometry is pulled from the parent shape
//   thickness = Used to set the width of the flyout and text. Default: `0.5`
// Example:
//   cyl(d1=30, d2=13, h=30, orient=FWD+UP)
//       #parent_geom_debug_axis();
//
module parent_geom_debug_axis(geom=undef, thickness=0.5) {
    geom_ = _first([ geom, Geom() ]);
    axis = geom_axis(geom_); 
    length = geom_length(geom_);
    if (_defined(axis) && length > 0)
        dashed_stroke(
            [
                apply(move(axis * (length *  0.7)), CENTER),
                apply(move(axis * (length * -0.7)), CENTER)
            ],
            [3, 2],
            width=thickness);
}


// Module: parent_geom_debug_anchors()
// Synopsis: Display named anchor debugging information for a given shape
// Usage:
//   parent_geom_debug_anchors();
//   parent_geom_debug_anchors(<geom=undef>, <full=false>, <thickness=0.5>);
// Description:
//   As a child module, display anchor information for geometry 
//   named anchors. Named anchors listed within the parent's 
//   attachable geometry, or optionally within the `geom` argument,
//   are displayed as individual flyouts that point to the 
//   anchor's position. If the argument `full` is set to `true`, 
//   the anchor's position, orientation, and spin values are 
//   displayed beneath the anchor's name.
// Arguments:
//   geom = An instantiated Geom object. Default: `undef`, in which case the geometry is pulled from the parent shape
//   full = If set to `true`, the full information of a named anchor is displayed. Default: `false`
//   thickness = Used to set the width of the flyout and text. Default: `0.5`
// Example:
//   // this "plate" module sets up four named anchors:
//   module plate(anchor=CENTER, spin=0, orient=UP) {
//       size = [20, 20, 1];
//       anchors = [
//           named_anchor("A", [-10, -10, 1], UP, 0),
//           named_anchor("B", [-10, 10, 1], UP, 0),
//           named_anchor("C", [10, 10, 1], UP, 0),
//           named_anchor("D", [10, -10, 1], UP, 0),
//           ];
//       attachable(anchor, spin, orient, size=size, anchors=anchors) {
//           cuboid(size, anchor=CENTER);
//           children();
//       }
//   }
//   // now, invoke the plate, and debug its named anchors. For fun, spin the plate a bit:
//   plate(spin=20)
//       #parent_geom_debug_anchors();
//
module parent_geom_debug_anchors(geom=undef, full=false, thickness=0.5) {
    geom_ = _first([ geom, Geom() ]);
    anchors = geom_anchors(geom_, default=[]);
    for (i=idx(anchors)) {
        anchor = anchors[i];
        flyout_to_pos(anchor[1], leg1=15 * (i + 1), leg2=5 * (i + 1), thickness=thickness)
            attach("flyout-text", LEFT)
                attachable_text3d_multisize(
                    (full)
                        ? [
                            [[anchor[0]], 3],
                            [[  str(anchor[1]),
                                str("orient: ", anchor[2]), // webdings: `l`
                                str("spin: ",   anchor[3])  // webdings: `q`
                                ], 2],
                            ]
                        : [[[anchor[0]], 3]]
                    );
    }
}


// Module: parent_geom_debug_bounding_box()
// Synopsis: Draw a bounding box around a given shape
// Usage: as a module
//   [ATTACHABLE] parent_geom_bounding_box( [vnf=vnf | geom=geom | size=size] );
//   [ATTACHABLE] parent_geom_bounding_box( [vnf=vnf | geom=geom | size=size], <width=0.5>, <anchor=CENTER>, <spin=0>, <orient=UP>);
// Description:
//   Given one of three different sources - a BOSL2 parent geometry `geom`, a 
//   supplied VNF list `vnf`, or direct sizing list `size`, establish the outer bounding 
//   box as a set of cube dimensions. `parent_geom_debug_bounding_box()` will model a VNF wireframe cube, 
//   centered at the parent attachable's location, describing the outer boundary box of the shape. 
//   The wireframe structure's line width is adjustable with the `width` argument.
//
// Arguments: as a module
//   vnf = a list of VNF coordinates. No default
//   geom = BOSL2 parent geomety. If unspecified, and `$parent_geom` is set, `$parent_geom` will be used. No default
//   size = a list of dimensions, form of `[x-len, y-len, z-len]`. No default
//   ---
//   width = the width of lines to draw for the boundary box. Default: `0.5`
//   anchor = Translate so anchor point is at origin `[0,0,0]`. Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchoring. Default: `0`
//   orient = Vector direction to which the model should point after spin. Default: `UP`
//
// Example: a basic boundary around a basic sphere:
//   sphere(d=20)
//      #parent_geom_debug_bounding_box();
//
module parent_geom_debug_bounding_box(geom=undef, size=undef, vnf=undef, width=0.5, anchor=CENTER, spin=0, orient=UP) {
    geom_ = _first([geom, Geom()]);
    assert(_defined(geom_) || _defined(vnf) || _defined(size));
    bounding = parent_geom_bounding_box(geom=geom_, size=size, vnf=vnf);
    if (_defined(bounding))
        attachable(anchor, spin, orient, size=bounding) {
            vnf_wireframe(cube(bounding, anchor=CENTER), width=width);
            children();
        }
}


// Section: Geometry Debugging Functions
//
// Function: parent_geom_bounding_box()
// Synopsis: Obtain a boundary box surrounding an attachable shape
// Usage:
//   boundary = parent_geom_bounding_box();
//   boundary = parent_geom_bounding_box( [vnf=vnf | geom=geom | size=size] );
// Description:
//   Given one of three different sources - a BOSL2 parent geometry `geom`, a 
//   supplied VNF list `vnf`, or direct sizing list `size`, establish the outer bounding 
//   box as a set of cube dimensions. 
//   `parent_geom_bounding_box()` returns those cube dimensions as `boundary`, which 
//   should reasonably approximate the outer boundaries of a shape, in the form `[x, y, z]` 
//   .
//   `parent_geom_bounding_box()` will look at the arguments `size`, `vnf`, and `geom` in 
//   that order to determine the dimensions of the shape. `geom` will be filled with 
//   `$parent_geom` if `geom` is unspecified and `$parent_geom` is available. 
//   When the geometry type of `geom` is  `vnf_extents`, `parent_geom_bounding_box()` 
//   will do the right thing and interpret it as a VNF. 
//
// Arguments: as a function
//   vnf = a list of VNF coordinates. No default
//   geom = BOSL2 parent geomety. If unspecified, and `$parent_geom` is set, `$parent_geom` will be used. No default
//   size = a list of dimensions, form of `[x-len, y-len, z-len]`. No default
//
// Example(NORENDER): specifying an established VNF shape to build a bounding box:
//   shape = sphere(r=10);
//   boundary = parent_geom_bounding_box(vnf=shape);
//   // boundary = [20, 20, 20]
//
// Example(NORENDER): specifying `size` as a boundary argument:
//   boundary = parent_geom_bounding_box(size=[20, 20, 20]);  
//   // boundary == [20, 20, 20]
//
function parent_geom_bounding_box(geom, size=undef, vnf=undef) =
    let(
        geom_ = (_defined(geom)) ? geom : (_defined($parent_geom)) ? Geom() : undef,
        geom_type = geom_type(geom_),
        v = geom_vnf(geom_, default=vnf)
        )
    assert(_defined(geom_) || _defined(v) || _defined(size))
    let(
        bounding = (_defined(size))
            ? size
            : (_defined(v))
                ? [ path_length([[min_vnf_x(v), 0, 0], [max_vnf_x(v), 0, 0]]), 
                    path_length([[0, min_vnf_y(v), 0], [0, max_vnf_y(v), 0]]), 
                    path_length([[0, 0, min_vnf_z(v)], [0, 0, max_vnf_z(v)]]) ]
                : (geom_type == "spheroid")
                    ? [ geom_radius1(geom_) * 2, 
                        geom_radius1(geom_) * 2, 
                        geom_length(geom_) ]
                    : (geom_type == "prismoid")
                        ? [ max([geom_size(geom_).x, geom_size2(geom_).x]),
                            max([geom_size(geom_).y, geom_size2(geom_).y]),
                            geom_length(geom_) ]
                        : (geom_type == "conoid")
                            ? [ max([geom_radius1(geom_), geom_radius2(geom_)]) * 2,
                                max([geom_radius1(geom_), geom_radius2(geom_)]) * 2,
                                geom_length(geom_) ]
                            : (geom_type == "vnf_extent")
                                ? log_fatal(["parent_shape_maxsize_bounding_box(): ",
                                    "should have already processed VNF"])
                                : log_error_assign([], 
                                    ["Unknown bounding box for geom type ", 
                                    geom_type, "; returning "])
        )
    assert(_defined(bounding))
    bounding;


// Function: position_from_center_to_vector()
// Synopsis: Return the 3D position of a cardinal or named anchor based on a shape's geometry
// Usage:
//   point = position_from_center_to_vector(vec);
//   point = position_from_center_to_vector(vec, <geom=undef>, <cp=CENTER>);
// Description:
//   Given a vector `vec` and optionally a Geom geometry object `geom`, 
//   return the position of the outer edge of the boundary in the 
//   direction of the vector, from the centerpoint. 
//   This currently ONLY works with cardinal vectors and named anchors: arbtrary 
//   vectors are not yet supported.  
//   Optionally, `path_from_center_to_vector()` can take a `cp` argument to use 
//   that as the centerpoint of the shape instead of `CENTER`. 
// Arguments:
//   vec = A cardinal or named anchor point. No default
//   ---
//   geom = An instantiated Geom object. Default: `undef` (in which case, the geometry will be gleaned from Geom() directly)
//   cp = An alternate centerpoint to be used as the path's starting point. Default: `CENTER`
// Todo:
//   Support arbitrary vectors beyond just `TOP`, `BOTTOM+RIGHT+FWD`, `my-named-anchor`
//
function position_from_center_to_vector(vec, geom=undef, cp=CENTER) =
    let(
        geom_ = _first([ geom, Geom() ])
    )
    assert(_defined(geom_) && obj_is_obj(geom_))
    let(
        res = _find_anchor(vec, ParentGeom(geom_))
    )
    assert(_defined(res), str("position_from_center_to_vector(): Specified vector ", vec, " not found in geometry."))
    res[1];


// Function: path_from_center_to_vector()
// Synopsis: return a path from the center of a shape to a cardinal vector or anchor point
// Usage:
//   path = path_from_center_to_vector(vec);
//   path = path_from_center_to_vector(vec, <geom=undef>, <cp=CENTER>);
// Description:
//   Given a vector `vec`, and optionally a Geom object describing a shape `geom`, 
//   return the path from the shape's centerpoint to the cardinal or anchorable 
//   position at the specified vector, as `path`. 
//   Optionally, `path_from_center_to_vector()` can take a `cp` argument to use 
//   that as the centerpoint of the shape instead of `CENTER`. 
// Arguments:
//   vec = A cardinal or named anchor point. No default
//   ---
//   geom = An instantiated Geom object. Default: `undef` (in which case, the geometry will be gleaned from Geom() directly)
//   cp = An alternate centerpoint to be used as the path's starting point. Default: `CENTER`
//
function path_from_center_to_vector(vec, geom=undef, cp=CENTER) =
    let(
        pos = position_from_center_to_vector(vec, geom=geom, cp=cp)
    ) [cp, pos];


/// Section: Misc Glue Functions
///

/// max_vnf set:
/// max_vnf_x(), min_vnf_x(): given a VNF structure (BOSL2specific) find 
/// the maximum "x" dimension in that structure and return it (or the min, 
/// depending on which was called). This applies to the 'y' and 'z' dimensions 
/// also (so, min_vnf_z() and max_vnf_y(), etc). 
/// TODO- write some unit tests for these please. 
/// TODO- document these please.
function _axis_vnf_xs(vnf) = [for (p=vnf[0]) p.x];
function _axis_vnf_ys(vnf) = [for (p=vnf[0]) p.y];
function _axis_vnf_zs(vnf) = [for (p=vnf[0]) p.z];

function max_vnf_x(vnf) = max(_axis_vnf_xs(vnf));
function max_vnf_y(vnf) = max(_axis_vnf_ys(vnf));
function max_vnf_z(vnf) = max(_axis_vnf_zs(vnf));

function min_vnf_x(vnf) = min(_axis_vnf_xs(vnf));
function min_vnf_y(vnf) = min(_axis_vnf_ys(vnf));
function min_vnf_z(vnf) = min(_axis_vnf_zs(vnf));


/// Section: Geom Object Functions
///   These functions leverage the OpenSCAD Object library to create an Geometry Object and its attribute accessors.
///   See https://github.com/jon-gilbert/openscad_objects/blob/main/docs/HOWTO.md for a quick primer on constructing and
///   using Objects; and https://github.com/jon-gilbert/openscad_objects/blob/main/docs/object_common_functions.scad.md for
///   details on Object functions.
///
/// Subsection: Object Creation
///
/// Constant: Geom_attrs
/// Description:
///   A list of all `geom` attributes.
/// Attributes:
///   type = s = The name of the type of geometry in the object (eg, "prismoid", or "conoid").
///   radius1 = i = The value of the radius, or the bottom radius when a conoid has two radii. `radius1` has a `radius` and `r1` synonym.
///   radius2 = i = The value of the top radius when a conoid has two radii. `radius2` has an `r2` synonym.
///   centerpoint = i = The centerpoint of the geometry. `centerpoint` has a `cp` synonym. Default: `[]`
///   length = i = The length of the geometry. `length` has a `l` synonym.
///   shift = l = The geometry's shift. Default: `[]`
///   axis = l = The geometry's axis. Default: `[]`
///   offset = l = The offset of the geometry. Default: `[]`
///   anchors = l = The geometry's named anchors. Default: `[]`
///   size = l = The geometry's size, when the shape is a prismoid. Default: `[]`
///   size2 = l = The geometry's top size, when the shape is a prismoid and it has two different sizes of top and bottom. Default: `[]`
///   vnf = l = The VNF listing for the geometry, if the shape type is a VNF. Default: `[]`
///   region = l = The region listing for the geometry. Default: `[]`
///   twist = i = The twist of the shape. No default.
///
Geom_attrs = [
    "_geom=l",
    "type=s",
    "radius1=i",                // r1
    "radius2=i",                // r2
    ["centerpoint", "l", []],   // cp
    "length=i",                 // l
    ["shift", "l", []],
    ["axis", "l", UP],
    ["offset", "l", []],
    ["anchors", "l", []],
    ["size", "l", []],
    ["size2", "l", []],
    ["vnf", "l", []],
    ["region", "l", []],
    "twist=i"
];


/// Function: Geom()
/// Synopsis: Produce a Geom object 
/// Usage:
///   geom = Geom();
///   geom = Geom(<parent_geom=undef>, <vlist=[]>, <mutate=[]>);
/// Description:
///   Produce a Geom object, by interpreting an attachable's `$parent_geom` into 
///   the attributes of a Geom object.
///
/// Arguments:
///   parent_geom = Provide a `$parent_geom` instead of gleaning one from the parent-child hierarch. Default: `undef`
///   vlist = Variable list of attributes and values, eg: `[["length", 10], ["style", undef]]`. Default: `[]`.
///   mutate = An existing `Geom` object on which to pre-set object values. Default: `[]`.
///
/// Continues:
///   It is an error to call Geom() with a parent geometry that does not have a valid "type".
/// 
function Geom(parent_geom=undef, vlist=[], mutate=[]) =
    let(
        p = (_defined(parent_geom) && len(parent_geom) > 0) 
            ? parent_geom 
            : _defined($parent_geom)
                ? $parent_geom
                : [],
        t = _defined(p) ? p[0] : "none",
        u = undef
    )
    assert(_defined(t))
    let(
        // reorder and extend the parent_geom according to the below attr_names based on type:
        attr_names = [ "type", "radius1", "radius2", "centerpoint", "length", "shift", "axis", 
                       "offset", "anchors", "size", "size2", "vnf", "region", "twist" ],
        reordered_vals = (t == "none")
            ? [t, u, u, u, u, u, u, u, u, u, u, u, u, u]
            : (t == "conoid") // ["conoid", r1, r2, l, shift, axis, cp, offset, anchors]
                ? [t, p[1], p[2], p[6], p[3], p[4], p[5], p[7], p[8], u, u, u, u, u]
                : (t == "prismoid") // ["prismoid", size, size2, shift, axis, over_f, cp, offset, anchors]
                    ? [t, u, u, p[5], u, p[3], p[4], p[6], p[8], p[1], p[2], u, u, u]
                    : (t == "spheroid") // ["spheroid", r1, cp, offset, anchors]
                        ? [t, p[1], u, p[2], u, u, u, p[3], p[4], u, u, u, u, u]
                        : (t == "vnf_extent") // ["vnf_extent", vnf, cp, offset, anchors]
                            ? [t, u, u, p[2], u, u, u, p[3], p[4], u, u, p[1], u, u]
                            : (t == "vnf_isect") // ["vnf_isect", vnf, cp, offset, anchors]
                                ? [t, u, u, p[2], u, u, u, p[3], p[4], u, u, p[1], u, u]
                                : (t == "rgn_extent") // ["rgn_extent", region, cp, offset, anchors]
                                    ? [t, u, u, p[2], u, u, u, p[3], p[4], u, u, u, p[1], u]
                                    : (t == "rgn_isect") // ["rgn_isect", region, cp, offset, anchors]
                                        ? [t, u, u, p[2], u, u, u, p[3], p[4], u, u, u, p[1], u]
                                        : (t == "extrusion_extent") // ["extrusion_extent", region, l, twist, scale, shift, cp, offset, anchors]
                                            ? [t, u, u, p[6], p[2], p[5], u, p[7], p[8], u, u, u, p[1], p[3]]
                                            : (t == "extrusion_isect") // ["extrusion_isect", region, l, twist, scale, shift, cp, offset, anchors]
                                                ? [t, u, u, p[6], p[2], p[5], u, p[7], p[8], u, u, u, p[1], p[3]]
                                                : (t == "point") // ["point", cp, offset, anchors]
                                                    ? [t, u, u, p[1], u, u, u, p[2], p[3], u, u, u, u, u]
                                                    : (t == "ellipse") //  ["ellipse", r1, cp, offset, anchors]
                                                        ? [t, p[1], u, p[2], u, u, u, p[3], p[4], u, u, u, u, u]
                                                        : (t == "trapezoid") // ["trapezoid", point2d(size), size2, shift, over_f, cp, offset, anchors]
                                                            ? [t, u, u, p[5], l, p[3], u, p[6], p[7], p[1], p[2], u, u, 
                                                                log_warning_assign(p[4], "Geom(): placing 'over_f' into the 'twist' attribute")]
                                                            : log_fatal(["Can't interpret a parent geometry of ", t]),
        // re-fold the attr names and values into a single vlist:
        gleaned_vlist = flatten( [for (i=idx(attr_names)) [attr_names[i], reordered_vals[i]]] ),
        merged_vlist = concat(vlist, gleaned_vlist)
    )
    Object("Geom", Geom_attrs, vlist=merged_vlist, mutate=mutate);


function ParentGeom(geom) =
    assert(obj_is_obj(geom) && obj_toc_get_type(geom) == "Geom")
    let(
        t = geom_type(geom),
        parent_geom_names_by_type = [
            ["conoid",           ["type", "radius1", "radius2", "length", "shift", "axis", "centerpoint", "offset", "anchors"] ],
            ["prismoid",         ["type", "size", "size2", "shift", "axis", "centerpoint", "offset", "anchors"] ],
            ["spheroid",         ["type", "radius1", "centerpoint", "offset", "anchors"] ],
            ["vnf_extent",       ["type", "vnf", "centerpoint", "offset", "anchors"] ],
            ["vnf_isect",        ["type", "vnf", "centerpoint", "offset", "anchors"] ],
            ["rgn_extent",       ["type", "region", "centerpoint", "offset", "anchors"] ],
            ["rgn_isec",         ["type", "region", "centerpoint", "offset", "anchors"] ],
            ["extrusion_extent", ["type", "region", "length", "twist", "scale", "shift", "centerpoint", "offset", "anchors"] ],
            ["extrusion_isect",  ["type", "region", "length", "twist", "scale", "shift", "centerpoint", "offset", "anchors"] ],
            ["point",            ["type", "centerpoint", "offset", "anchors"] ],
            ["ellipse",          ["type", "radius1", "centerpoint", "offset", "anchors"] ],
            ["trapezoid",        ["type", "size", "size2", "shift", "over_f", "centerpoint", "offset", "anchors"] ],
        ],
        parent_geom_names = list_remove_values(
            [for (pair=parent_geom_names_by_type) (pair[0] == t) ? pair[1] : undef],
            [undef],
            all=true)[0]
    )
    [ for (n=parent_geom_names) obj_accessor_get(geom, n) ];


/// Subsection: Strut Object Attribute Accessor Functions
///
function geom_type(g, default=undef, nv=undef)          = obj_accessor(g, "type", default=default, nv=nv);
function geom_radius1(g, default=undef, nv=undef)       = obj_accessor(g, "radius1", default=default, nv=nv);
function geom_radius2(g, default=undef, nv=undef)       = obj_accessor(g, "radius2", default=default, nv=nv);
function geom_centerpoint(g, default=undef, nv=undef)   = obj_accessor(g, "centerpoint", default=default, nv=nv);
function geom_length(g, default=undef, nv=undef)        = 
    let(
        type = geom_type(g),
        _ = log_error_if((type != "conoid" && _defined(nv)), 
            ["geom_length(): value supplied for 'nv', but type ", 
                type, "won't support that. Use an attr-native accessor to change this length"]),
        current_len = (type == "conoid")
            ? obj_accessor(g, "length", default=default, nv=nv)
            : (type == "prismoid")
                ? obj_accessor(g, "size", default=undef, nv=undef).z
                : (type == "spheroid")
                    ? obj_accessor(g, "radius1", default=undef, nv=undef) * 2
                    : log_fatal(["geom_length(): Don't yet know how to get a 'length' from type ", type])
    ) current_len;
function geom_shift(g, default=undef, nv=undef)         = obj_accessor(g, "shift", default=default, nv=nv);
function geom_axis(g, default=undef, nv=undef)          = obj_accessor(g, "axis", default=default, nv=nv);
function geom_offset(g, default=undef, nv=undef)        = obj_accessor(g, "offset", default=default, nv=nv);
function geom_anchors(g, default=undef, nv=undef)       = obj_accessor(g, "anchors", default=default, nv=nv);
function geom_size(g, default=undef, nv=undef)          = obj_accessor(g, "size", default=default, nv=nv);
function geom_size2(g, default=undef, nv=undef)         = obj_accessor(g, "size2", default=default, nv=nv);
function geom_vnf(g, default=undef, nv=undef)           = obj_accessor(g, "vnf", default=default, nv=nv);
function geom_region(g, default=undef, nv=undef)        = obj_accessor(g, "region", default=default, nv=nv);
function geom_twist(g, default=undef, nv=undef)         = obj_accessor(g, "twist", default=default, nv=nv);


/// Subsection: Aliased Attribute Functions
///
function geom_radius(g, default=undef, nv=undef) = 
    log_info_assign(obj_accessor(g, "radius1", default=default, nv=nv), 
        "geom_radius() is an alias for geom_radius1()");
function geom_r1(g, default=undef, nv=undef) = 
    log_info_assign(obj_accessor(g, "radius1", default=default, nv=nv), 
        "geom_r1() is an alias for geom_radius1()");
function geom_r2(g, default=undef, nv=undef) = 
    log_info_assign(obj_accessor(g, "radius2", default=default, nv=nv), 
        "geom_r2() is an alias for geom_radius2()");
function geom_cp(g, default=undef, nv=undef) = 
    log_info_assign(obj_accessor(g, "centerpoint", default=default, nv=nv), 
        "geom_cp() is an alias for geom_centerpoint()");
function geom_l(g, default=undef, nv=undef) = 
    log_info_assign(obj_accessor(g, "length", default=default, nv=nv), 
        "geom_l() is an alias for geom_length()");

