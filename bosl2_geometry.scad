// LibFile: bosl2_geometry.scad
//   Reinterpretaion of the BOSL2's `$parent_geom` list into an Object.
//
// Includes:
//   include <bosl2_geometry.scad>
//

include <object_common_functions.scad>

/// Wow. So, I really didn't want to write this.

// Section: Geom Object 
//
// Subsection: Object Creation
//
// Constant: Geom_attrs
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

// Function: Geom()
function Geom(pg=[], vlist=[], mutate=[]) =
    let(
        p = (_defined(pg) && len(pg) > 0) 
            ? pg 
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
                : (t == "prismoid") // ["prismoid", size, size2, shift, axis, cp, offset, anchors]
                    ? [t, u, u, p[5], u, p[3], p[4], p[6], p[7], p[1], p[2], u, u, u]
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


// Subsection: Strut Object Attribute Accessor Functions
//
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
                    : log_fatal(["geom_length(): Don't yhet know how to get a 'length' from type ", type])
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
//
// Subsection: Aliased Attribute Functions
//
function geom_radius(g, default=undef, nv=undef)        = log_info_assign(obj_accessor(g, "radius1", default=default, nv=nv), "geom_radius() is an alias for geom_radius1()");
function geom_r1(g, default=undef, nv=undef)            = log_info_assign(obj_accessor(g, "radius1", default=default, nv=nv), "geom_r1() is an alias for geom_radius1()");
function geom_r2(g, default=undef, nv=undef)            = log_info_assign(obj_accessor(g, "radius2", default=default, nv=nv), "geom_r2() is an alias for geom_radius2()");
function geom_cp(g, default=undef, nv=undef)            = log_info_assign(obj_accessor(g, "centerpoint", default=default, nv=nv), "geom_cp() is an alias for geom_centerpoint()");
function geom_l(g, default=undef, nv=undef)             = log_info_assign(obj_accessor(g, "length", default=default, nv=nv), "geom_l() is an alias for geom_length()");


// Section: Modules
//
// Constant: HIGHLIGHT_COLOR
HIGHLIGHT_COLOR = "OrangeRed";


// Module: parent_geom_debug()
module parent_geom_debug() {
    w = 0.4;
    g = Geom();
    b = parent_geom_bounding_box();
    color(HIGHLIGHT_COLOR) {

        parent_geom_debug_axis(g=g, w=w);
        
        parent_geom_debug_bounding_box(geom=g);

        if (geom_anchors(g))
            parent_geom_debug_anchors(g, b);

        if (geom_vnf(g))
            vnf_wireframe(vnf, width=w);

        flyout_to_pos(geom_centerpoint(g), leader=10, thickness=w, color=HIGHLIGHT_COLOR, alpha=1, offset_len=half(b.x))
            attach("flyout-text", LEFT)
                attachable_text3d_multisize(
                    [
                        [[geom_type(g)], 5],
                        [
                            list_remove_values([
                                str("Dimension boundary: ", b),
                                (_defined_and_nonzero(geom_radius1(g)) || _defined_and_nonzero(geom_radius2(g)))
                                    ? str("Radii: ", geom_radius1(g), ", ", geom_radius2(g, default="[none]")) : undef,
                                (_defined(geom_size(g)))
                                    ? str("Sizes: ", geom_size(g), ", ", geom_size2(g, default="[none]")) : undef,
                                (geom_length(g) > 0)
                                    ? str("Length: ", geom_length(g)) : undef,
                                (_defined(geom_axis(g)))
                                    ? str("Axis: ", geom_axis(g)) : undef,
                                (_defined(geom_anchors(g)) && len(geom_anchors(g)) > 0)
                                    ? str("Anchors: ", len(geom_anchors(g))) : undef,
                                (_defined(geom_shift(g)))
                                    ? str("Shift: ", geom_shift(g)) : undef,
                                (_defined(geom_offset(g)))
                                    ? str("Offset: ", geom_offset(g)) : undef,
                                (_defined(geom_vnf(g)) || _defined(geom_region(g)))
                                    ? str("Has a ", (_defined(geom_vnf(g))) ? "VNF " : "", (_defined(geom_region(g))) ? "region" : "") : undef,
                            ], [undef], all=true),
                            3
                        ],
                    ]);
    }
}


module parent_geom_debug_axis(g=undef, w=0.4) {
    g_ = _first([ g, Geom() ]);
    axis = geom_axis(g_); // TODO: pull origin if no axis provided?
    length = geom_length(g_);
    if (_defined(axis) && length > 0)
        dashed_stroke(
            [
                apply(move(axis * (length *  0.7)), CENTER),
                apply(move(axis * (length * -0.7)), CENTER)
            ],
            [3, 2],
            width=w);
}


module parent_geom_debug_anchors(g=undef, b=undef, full=false, w=0.4) {
    g_ = _first([ g, Geom() ]);
    b_ = _first([ b, parent_geom_bounding_box() ]);
    anchors = geom_anchors(g_, default=[]);
    if (len(anchors) > 0)
        for (a=anchors)
            flyout_to_pos(a[1], leg1=15, leg2=5, offset_len=half(b.x), spin=180)
                attach("flyout-text", LEFT)
                    attachable_text3d_multisize(
                        (full)
                            ? [
                                [[a[0]], 3],
                                [[  str(a[1]),
                                    str("orient: ", a[2]), // webdings: `l`
                                    str("spin: ", a[3]) // webdings: `q`
                                    ], 2],
                                ]
                            : [[[a[0]], 3]]
                        );
}

// Function&Module: parent_geom_bounding_box()
// Usage: as a function
//   boundary = parent_geom_bounding_box();
//   boundary = parent_geom_bounding_box(<vnf=vnf>, <geom=geom>, <size=size>);
// Usage: as a module
//   [ATTACHABLE] parent_geom_bounding_box();
//   [ATTACHABLE] parent_geom_bounding_box(<width=0.5>, <anchor=CENTER>, <spin=0>, <orient=UP>);
//
// Description:
//   Given one of three different sources - a BOSL2 parent geometry `geom`, a 
//   supplied VNF list `vnf`, or direct sizing list `size`, establish the outer bounding 
//   box as a set of cube dimensions. 
//   .
//   `parent_geom_bounding_box()` will look at the arguments `size`, `vnf`, and `geom` in 
//   that order to determine the dimensions of the shape. `geom` will be filled with 
//   `$parent_geom` if `geom` is unspecified and `$parent_geom` is available. 
//   When the geometry type of `geom` is  `vnf_extents`, `parent_geom_bounding_box()` 
//   will do the right thing and interpret it as 
//   a VNF. 
//   .
//   When called as a function, `parent_geom_bounding_box()` returns cube dimensions `boundary` that 
//   should reasonably approximate the outer boundaries of a shape, in the form `[x, y, z]` 
//   .
//   When called as a module, `parent_geom_bounding_box()` will model a VNF wireframe cube, centered 
//   at the parent attachable's location. The wireframe structure's line width is adjustable with the `width`
//   argument, which defaults at `0.5`.
//
// Arguments: as a function
//   vnf = a list of VNF coordinates. No default
//   geom = BOSL2 parent geomety. If unspecified, and `$parent_geom` is set, `$parent_geom` will be used. No default
//   size = a list of dimensions, form of `[x-len, y-len, z-len]`. No default
//
// Arguments: as a module
//   vnf = a list of VNF coordinates. No default
//   geom = BOSL2 parent geomety. If unspecified, and `$parent_geom` is set, `$parent_geom` will be used. No default
//   size = a list of dimensions, form of `[x-len, y-len, z-len]`. No default
//   ---
//   width = the width of lines to draw for the boundary box. Default: `0.5`
//   anchor = Translate so anchor point is at origin `[0,0,0]`. Default: `AXLE_DEFAULT_ANCHOR`
//   spin = Rotate this many degrees around the Z axis after anchoring. Default: `AXLE_DEFAULT_SPIN`
//   orient = Vector direction to which the model should point after spin. Default: `AXLE_DEFAULT_ORIENT`
//
// Example: a basic boundary around a basic sphere:
//   sphere(d=20)
//      #parent_geom_bounding_box();
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
        g = (_defined(geom)) ? geom : (_defined($parent_geom)) ? Geom() : undef,
        type = geom_type(g),
        v = geom_vnf(g, default=vnf)
        )
    assert(_defined(g) || _defined(v) || _defined(size))
    let(
        bounding = (_defined(size))
            ? size
            : (_defined(v))
                ? [ path_length([[min_vnf_x(v), 0, 0], [max_vnf_x(v), 0, 0]]), 
                    path_length([[0, min_vnf_y(v), 0], [0, max_vnf_y(v), 0]]), 
                    path_length([[0, 0, min_vnf_z(v)], [0, 0, max_vnf_z(v)]]) ]
                : (type == "spheroid")
                    ? [ geom_radius1(g) * 2, 
                        geom_radius1(g) * 2, 
                        geom_length(g) ]
                    : (type == "prismoid")
                        ? [ max([geom_size(g).x, geom_size2(g).x]),
                            max([geom_size(g).y, geom_size2(g).y]),
                            geom_length(g) ]
                        : (type == "conoid")
                            ? [ max([geom_radius1(g), geom_radius2(g)]) * 2,
                                max([geom_radius1(g), geom_radius2(g)]) * 2,
                                geom_length(g) ]
                            : (type == "vnf_extent")
                                ? log_fatal(["parent_shape_maxsize_bounding_box(): ",
                                    "should have already processed VNF"])
                                : log_error_assign([], 
                                    ["Unknown bounding box for geom type ", 
                                    type, "; returning "])
        )
    assert(_defined(bounding))
    bounding;


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


// give a vector and optionally a Geom geometry object, 
// return the position of the outer edge of the boundary in the 
// direction of the vector, from the centerpoint. 
// Currently ONLY works with cardinal vectors and named anchors. 
//
function position_from_center_to_vector(vec, geom=undef, cp=CENTER) =
    let(
        geom_ = (_defined(geom) && obj_is_obj(geom))
            ? geom
            : Geom()
    )
    assert(_defined(geom_) && obj_is_obj(geom_))
    let(
        res = _find_anchor(vec, ParentGeom(geom_))
    )
    assert(_defined(res), str("position_from_center_to_vector(): Specified vector ", vec, " not found in geometry."))
    res[1];


// given a vector and optionally a Geom object, 
// return the path from the centerpoint to the anchorable 
// position at the specified vector. 
function path_from_center_to_vector(vec, geom=undef, cp=CENTER) =
    let(
        pos = position_from_center_to_vector(vec, geom=geom, cp=cp)
    ) [cp, pos];


function _defined_and_nonzero(a) = _defined(a) && a != 0;

// max_vnf set:
// max_vnf_x(), min_vnf_x(): given a VNF structure (BOSL2specific) find 
// the maximum "x" dimension in that structure and return it (or the min, 
// depending on which was called). This applies to the 'y' and 'z' dimensions 
// also (so, min_vnf_z() and max_vnf_y(), etc). 
// TODO- write some unit tests for these please. 
// TODO- document these please.
function _axis_vnf_xs(vnf) = [for (p=vnf[0]) p.x];
function _axis_vnf_ys(vnf) = [for (p=vnf[0]) p.y];
function _axis_vnf_zs(vnf) = [for (p=vnf[0]) p.z];

function max_vnf_x(vnf) = max(_axis_vnf_xs(vnf));
function max_vnf_y(vnf) = max(_axis_vnf_ys(vnf));
function max_vnf_z(vnf) = max(_axis_vnf_zs(vnf));

function min_vnf_x(vnf) = min(_axis_vnf_xs(vnf));
function min_vnf_y(vnf) = min(_axis_vnf_ys(vnf));
function min_vnf_z(vnf) = min(_axis_vnf_zs(vnf));



