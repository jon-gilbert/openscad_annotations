// LibFile: mechanical.scad
//   Methods for managing and annotating mechanical assignments onto 3D shapes and objects. 
//   Elements that are "mechanically aware" may be decorated with movement annotations 
//   that describe how they are meant to move; further more, aware elements may be 
//   attached to other elements with an movement-aware `mech_attach()`.
//
// Includes:
//   include <openscad_annotations/mechanical.scad>
//

include <openscad_annotations/common.scad>
include <openscad_annotations/bosl2_geometry.scad>

/// Section: Scope-level Constants
/// 
/// Constant: $_mech
/// Description: 
///   Holds the `mech` annotation object within the model.
///
$_mech = undef;


// Section: Mechanical Annotation Modules
//
// Function&Module: mech()
// Synopsis: assign mechanical metadata to models
// Usage: as a function
//   mech_object = mech(type);
//   mech_object = mech(type, <...>);
//
// Usage: as a module
//   mech(type) [CHILDREN];
//   mech(type, <...>) [CHILDREN];
//
// Description:
//   As a function, `mech()` returns a Mech mechanical object `mech_object` that describes movement for a specified 3D shape. Arguments passed 
//   to `mech()` are bounds-checked for sanity and suitable defaults are applied before calling `Mech()` to obtain 
//   `mech_object`. The returned object `mech_object` is suitable for use as a `$_mech` scoped variable, usable within the module version 
//   of `mech()`, as an argument to `mech_attach()`, or as a comparator with `mech_compare()`.
//   .
//   As a module, `mech()` applies a set of attributes as a mechanical description to children. Mechanical descriptions in this context 
//   assign out movement for one or more shapes, that can be later queried or annotated. Given a movement 
//   type `type` as a string, and any number of supported Mech attributes, `mech()` constructs a Mech 
//   object and passes it to the children beneath the `mech()` call. 
//   .
//   Arguments for function vs module use are identical. 
//   A mechanical type `type` must be provided, and that value must be one of the values listed in `MECH_TYPES`. 
//   All remaining arguments to `mech()` strive to have sensible defaults based on `type`. 
//   In some cases, the meaning of the argument changes based on the `type` of mechanical movement specified: for example, 
//   the `limit` argument when `type` is `rotational` or `oscillatory` is degrees of rotation, but when `type` is 
//   a `lateral` or `reciprocal`, `limit` is a measurement of linear distance traveled. 
//   .
//   A particularly noteworthy example of dual-use arguments is `direction`: both the meaning, and the allowable defaults, change 
//   based on the mechanical type `type`. When `type` is `rotational` or `oscillatory`, `direction` may be a list containing 
//   `cw`, or `ccw`, or both (eg, `["cw"]`, `["ccw"]`, or `["cw", "ccw"]`); when `type` is `lateral` or `reciprocal`, 
//   `direction` may be a list containing one or two vectors (eg, `[UP]`, `[RIGHT+FWD, LEFT+BACK]`). 
//   Setting defaults with `direction` changes based on `type` as well. When `type` is `lateral` or `rotational`, 
//   `direction` defaults to a single directional listing: `[UP]` for `lateral`, `["cw"]` for `rotational`. 
//   When `type` is `reciprocal` or `oscillatory`, `direction` will default to forward-back pairings: 
//   `[UP, DOWN]` for `reciprocal`, versus `["cw", "ccw"]` for `oscillatory`. `direction` will attempt to pair 
//   single values given: for `oscillatory` it'll match the opposite movement of `["ccw"]` to become `["ccw", "cw"]`; 
//   for `reciprocal`, it'll determine the opposite vector to whatever given, so a `direction` of just `UP` will become 
//   a list of `[UP, DOWN]`.
//   .
//   Mechanical assignment via module is hierarchical, in that all children beneath the `mech()` module call will 
//   have the same assignment. Mech assignment is singular, in that there is only ever one 
//   mech description assigned to a 3D element. 
//   .
//   Argument defaults are informed from the Mech defaults listed above.
//
// Arguments:
//   type = One of `rotational`, `oscillatory`, `lateral`, or `reciprocal`. No default
//   ---
//   direction = For `rotational` and `oscillatory` types, can be one of `cw`, `ccw`. For `lateral` and `reciprocal` types, can be one of `up`, `down`, or `both`. Default: `up` for a type of `lateral`; `both` for a type of `reciprocal`, `oscillatory`, and `rotational`.
//   limit = For `rotational` and `oscillatory` types, a measure of degrees, from `0` through `360`. For `lateral` and `reciprocal` types, a measure of a travelable length. Default: `360` for a type of `rotational` or `oscillatory`; `undef` otherwise.
//   geom = Specifies a geometry, with a BOSL2-derived Geom() object. Default: `undef`, meaning it will pull its value from the underlying shape. *(See bosl2_geometry.scad within 507common for details on this object type.)* 
//   axis = Specifies a central axis around which the movement will rotate. Default: `UP`
//   pivot_radius = For movements that pivot or rotate, sets the radius of the pivot. Default: `undef` (indicating the underlying model's dimensions will be used)
//   visual_offset = When annotating in a visual scene, use this value to offset the annotation from the underlying model. Default: `2`
//   visual_color = When annotating in a visual scene, use this color to identify movement annotation. Default: `blue`
//   visual_alpha = When annotating in a visual scene, use this value to set the transparency of the annotations. Default: `0.2`
//   visual_placements = When annotating in a visual scene, position annotations at this list of attachment points. Default: `[RIGHT]` *(as in, a list with a single element of `RIGHT` within it)*
//   visual_thickness = When annotating in a visual scene, set the annotations to this thickness. Default: `2`
//   visual_spin = When annotating in a visual scene, rotate the annotation around `pivot_radius` by this number of degrees. Default: `undef` (for no rotatation)
//   visual_limit = When annotating in a visual scene, apply this limit value without changing the `limit` attribute. Default: undef
//   clear = If set to `true`, will clear the current Mech assignment in the hirearchy, and ignore all other arguments in the call to `mech()`. Default: `false`
//
// Continues:
//   It is an error to specify a mechanical movement type that is not listed within `MECH_TYPES`. 
//   It is an error to specify a direction that is not a vector when working with a `lateral` or `reciprocal` movement type. 
//   It is an error to specify a direction that is neither `cw` nor `ccw` for a `rotational` or `oscillatory` movement type.
//
// Example(NORENDER): assigns a basic reciprocal movement to a rod:
//   mech("reciprocal", direction=[LEFT, RIGHT])
//      cuboid([40, 5, 5])
//
// Example(NORENDER): assigns a basic rotational movement to a cylinder, like a wheel:
//   mech("rotational")
//      cyl(d=20, h=2, orient=FWD);
//
// Example(NORENDER): similar assignment as above, but in this context the wheel is only meant to rotate clockwise: 
//   mech("rotational", direction="cw")
//      cyl(d=20, h=2, orient=FWD);
//
// Example(NORENDER): both cylinders in the hirearchy have the same rotational assignment:
//   mech("rotational", direction="cw")
//      cyl(d=20, h=2, orient=FWD)
//        attach(BOTTOM, TOP)
//          cyl(d=3, h=10);
//
// Example(NORENDER): the top cylinder has a clockwise rotation, the bottom cylinder has no mechanical assignment: 
//   mech("rotational", direction="cw")
//      cyl(d=20, h=2, orient=FWD)
//        attach(BOTTOM, TOP)
//          mech(clear=true)
//            cyl(d=3, h=10);
//
// Example(NORENDER): the top cuboid has a lateral assignment pointing down, and the bottom has a lateral assignment pointing up (the default); the sphere in the middle has no assignment:
//   mech("lateral", direction=DOWN)
//      cuboid([10, 10, 20])
//         attach(BOTTOM, TOP)
//            mech(clear=true)
//               sphere(10)
//                  attach(BOTTOM, TOP)
//                     mech("lateral")
//                        cuboid([10, 10, 20]);
//
// Todo: 
//   consider implementing progressively adaptable mech() calls (eg, `mech(limit=1) mech("rot") shape(r=10) mech("osc") shape2(r=20)`)
//
module mech(type, direction=undef, limit=undef, geom=undef, axis=undef, pivot=undef, pivot_radius=undef, visual_offset=undef, visual_color=undef, visual_alpha=undef, visual_placements=[], visual_thickness=undef, visual_spin=undef, visual_limit=undef, clear=false) {
    $_mech = mech(type,
        direction, limit, geom, axis,
        pivot, pivot_radius,
        visual_offset, visual_color,
        visual_alpha, visual_placements,
        visual_thickness, visual_spin, visual_limit,
        clear);
    children();
}

function mech(type, direction=undef, limit=undef, geom=undef, axis=undef, pivot=undef, pivot_radius=undef, visual_offset=undef, visual_color=undef, visual_alpha=undef, visual_placements=[], visual_thickness=undef, visual_spin=undef, visual_limit=undef, clear=false) =
    // I keep going back and forth here about whether we should have a shorthand 
    // for types (eg, "rot", "osc") and I'm writing here to remind myself later 
    // that <<No, we should not>>.
    (clear)
        ? undef
        : let(
            _ = log_fatal_unless(in_list(type, MECH_TYPES),
                    ["Unknown type", type, "; valid types are:", MECH_TYPES]),
            // ensure the provided limit is one that makes sense, particularly for 
            // rotational and oscillatory types:
            limit_ = (in_list(type, ["rotational", "oscillatory"]))
                ? let( l_ = _first([limit, 360]) )
                  (l_ < 0 || l_ > 360)
                    ? log_warning_assign(360, 
                            "limit out of bounds for this mech type; assigning")
                    : l_
                : limit,

            // ensure the direction provide is one that makes sense: 
            // for oscillatory and reciprocal, direction_ must be 2 items long.
            // for rotational and lateral, direction_ may be 1 or 2 items long.
            // for rotational and oscillatory, those items may only be `cw` or `ccw`, and 
            // neither of those must be repeated.
            // for lateral and reciprocal types, those items may only be vectors.
            direction_ = (in_list(type, ["rotational", "oscillatory"]))
                ? _mech_dir_from_arg_rotational(direction, type)
                : _mech_dir_from_arg_lateral(direction, type),

            // it may be tempting, but don't prepopulate geom automatically from 
            // $parent_geom if there is no geom argument to mech(); defer 
            // doing that until mechanical()
            geom_ = (_defined(geom))
                ? (obj_is_obj(geom) && obj_toc_get_type(geom) == "Geom")
                    ? geom
                    : log_error_assign(undef, 
                            "supplied geom argument must be a Geom object; using")
                : undef,

            visual_thickness_ = (_defined(visual_thickness)) 
                ? max([ visual_thickness, 0 ]) 
                : undef,

            visual_alpha_ = (_defined(visual_alpha)) 
                ? min([ visual_alpha, 1 ]) 
                : undef
            )
        Mech([
            "axis", axis,
            "type", type, 
            "direction", direction_,
            "limit", limit_,
            "geom", geom_,
            "pivot", pivot,
            "pivot_radius", pivot_radius,
            "visual_offset", visual_offset,
            "visual_color", visual_color,
            "visual_alpha", visual_alpha_,
            "visual_placements", visual_placements,
            "visual_thickness", visual_thickness_,
            "visual_spin", visual_spin,
            "visual_limit", visual_limit,
            ]);


/// Function: _mech_dir_from_arg_rotational()
/// Synopsis: validate direction attribute arguments for rotational mechanism types
function _mech_dir_from_arg_rotational(dir, type="rotational") =
    let(
        rotational_dirs = ["cw", "ccw"],
        d = (_defined(dir))
            ? (is_list(dir))
                ? dir
                : force_list(dir)
            : rotational_dirs,
        d_ = (len(unique(d)) == len(d))
            ? d
            : log_fatal("directional values for rotational or oscillatory mech types must be unique")
        
    )
    (type == "oscillatory") ? rotational_dirs : d_;


/// Function: _mech_dir_from_arg_lateral()
/// Synopsis: validate direction attribute arguments for lateral mechanism types
/// Description:
///   NOTE NOTE NOTE: reciprocal types that mirror may not be exactly comparative, 
///   do not expect DOWN+LEFT to completely mirror UP+RIGHT. 
function _mech_dir_from_arg_lateral(dir, type="lateral") =
    let(
        d = (_defined(dir))
            ? (is_vector(dir, 3))
                ? [dir]
                : (is_list(dir))
                    ? dir
                    : log_warning_assign(force_list(dir), ["unsure about forcing", dir, "to be a list here"])
            : (type == "lateral")
                ? [UP]
                : [UP, DOWN]
    )
    assert((len(d) == 1 || len(d) == 2), "Only one or two directions are permitted for lateral or reciprocal mech types")
    let(
        d_ = (type == "lateral")
            ? d
            : (len(d) == 1)
                ? [d[0], mirror(unit(d[0]), p=d[0])]
                : d
    )
    assert(is_vector(d_[0], 3)
        && ((_defined(d_[1])) ? is_vector(d_[1], 3) : true)
        )
    d_;


// Module: mechanical()
// Synopsis: produce mechanical annotation for a model
// Usage:
//   [ATTACHABLE] mechanical();
//   [ATTACHABLE] mechanical(mech_obj);
//
// Description:
//   When called as a child to an attachable element, `mechanical()` creates movement annotation arrows 
//   using a scope variable to describe the motion or movement of the element being annotated. 
//   .
//   Mechanical annotations such as directional arrows from `mechanical()` are shown while previewing models (as when a scene is shown using 
//   the Preview function, or by using `<F5>`). Annotations are not generated during a proper 
//   render (as when using `<F6>`): if annotations are needed within the scene in a render, 
//   set `RENDER_ANNOTATIONS` to `true` somewhere within your .scad file.
//
// Arguments:
//   m = An instatiated Mech object. No default, which should pull from the attachable parent's $_mech assignment
//   ---
//   visual_offset = If specified, this value will be used in place of the Mech object's `visual_offset` attribute. Default: `undef`
//   visual_color = If specified, this value will be used in place of the Mech object's `visual_color` attribute. Default: `undef`
//   visual_alpha = If specified, this value will be used in place of the Mech object's `visual_alpha` attribute. Default: `undef`
//   visual_placements = If specified, this list of placements will be used in place of the Mech object's `visual_placements` attribute. Default: `undef`
//   visual_thickness = If specified, this value will be used in place of the Mech object's `visual_thickness` attribute. Default: `undef`
//   visual_spin = If specified, this value will be used in place of the Mech object's `visual_spin` attribute. Default: `undef`
//   visual_limit = If specified, this value will be used in place of the Mech object's `visual_limit` attribute. Default: `undef`
//
// Continues:
//   It is an error to call `mechanical()` without first instantiating a Mech object (as with `mech()`). 
//   It is an error to call `mechanical()` against a Mech object with a type that isn't listed in `MECH_TYPES`. 
//   It is an error to call `mechanical()` as a child of a module that doesn't provide a positional geometry.
//
// Example: Basic lateral movement annotation: describes a bar that is meant to move upwards:
//   mech("lateral", direction=UP)
//       cuboid([10, 10, 50])
//           mechanical();
//   
// Example: Basic lateral movement annotation: describes a bar that is meant to move down:
//   mech("lateral", direction=DOWN)
//       cuboid([10, 10, 50])
//           mechanical();
//   
// Example: Lateral movement for a bar oriented to the left. Reorientation of the object doesn't change the mechanical movement of the object: the motion is still "up", even when the orientaiton of the object is to the left:
//   mech("lateral", direction=UP)
//       cuboid([10, 10, 50], orient=LEFT)
//           mechanical();
//   
// Example: Lateral movement for a bar oriented up, but that moves to the right: specifying an axis other than that of the geometry changes the movement. This is the opposite of the previous example: the orientation remains "up", but the movement is to the right. If you were to reorient the object to the right, the motion would appear in this scene to move down:
//   mech("lateral", axis=RIGHT, direction=UP)
//       cuboid([10, 10, 50])
//           mechanical();
/// THis is the xample that kind of shows how "axis" vs "direction" breaks down for lateral and reciprocal movements. 
/// I think this right here is why "axis" is mostlyh redundant, and we should just use "direction" as the key identify
/// for lateral and recip mech types. 
/// and then you look at an eexample with "both" as a direction, and it's clear again why there's a difference.
//   
// Example: Lateral movement for a bar, but that moves to back and to the left:
//   mech("lateral", axis=BACK+RIGHT, direction=UP)
//       cuboid([10, 10, 50])
//           mechanical();
//   
// Example: Basic reciprocal movement annotation: describes a bar that is meant to move upwards:
//   mech("reciprocal", direction=[UP, DOWN])
//       cuboid([10, 10, 50])
//           mechanical();
//   
// Example: Reciprical movement for a bar oriented to the left. Note that the `direction` argument is not given: reciprocal movements default to `[UP, DOWN]` as a direction.
//   mech("reciprocal")
//       cuboid([10, 10, 50], orient=LEFT)
//           mechanical();
//   
// Example: Reciprical movement for a bar oriented up, but that moves to the right: specifying an axis other than that of the geometry changes the movement:
//   mech("reciprocal", axis=RIGHT)
//       cuboid([10, 10, 50])
//           mechanical();
//   
// Example: Reciprical movement for a bar, but that moves to back and to the left:
//   mech("reciprocal", axis=BACK+RIGHT)
//       cuboid([10, 10, 50])
//           mechanical();
//   
// Example: Basic rotation: describes a rod that may freely spin on its axis:
//   mech("rotational")
//       cyl(d=10, h=50)
//           mechanical();
//   
// Example: Limited rotation: a rod that can only rotate 180 degrees around:
//   mech("rotational", limit=180)
//       cyl(d=10, h=50)
//           mechanical(visual_offset=10);
//   
// Example: Rotation annotated at multiple positions:
//   mech("rotational")
//       cyl(d=10, h=50)
//           mechanical(visual_placements=[TOP, BOTTOM]);
//   
// Example: Limited rotation and direction annotated: this cylinder may only rotation 270 degrees, and only counter-clockwise:
//   mech("rotational", limit=270, direction="ccw")
//       cyl(d=50, h=8)
//           mechanical();
//   
// Example: Placing a rotational annotation within a torus: setting a negative `visual_offset` contracts the annotation arrow to appear within the torus:
//   mech("rotational", limit=270)
//       torus(od=50, id=40)
//           mechanical(visual_offset=-8);
//
// Example: Basic oscillatory movement with a limit of 300-degrees of movement. Note that the placement of where the arrows are placed may not be where you want them:
//   mech("oscillatory", limit=300)
//       cyl(d=40, h=4)
//           mechanical();
//
// Example: Basic oscillatory movement with a 300-degree limit as above, but using the `visual_spin` argument the annotation can be rotated to present the center of the annotation towards FWD. (This is similar in practice to using `zrot()` or the `spin` argument to `attachable()`.) 
//   mech(type="oscillatory", limit=300)
//       cyl(d=40, h=4)
//           mechanical(visual_spin=120);
//   
// Example: Oscillational movement of a cobbled-together swinging pendulum. The oscillatory movement belongs to the pivoting "axle" at the top, since there's no overall attachable geometry for the whole shape. To do this in a way that makes sense, `pivot_radius` needs to be defined and set to the full length of the pendulum (in this case, the length of the stroke plus half the diameter less the overlap), and to clarify to where the movement is shown, `visual_spin` twists the annotation so that it's presented at the bottom:
//   mech("oscillatory", limit=120, pivot_radius=22)
//     cyl(d=8, h=5, orient=FWD){
//         attach(FWD, TOP, overlap=2)
//             cyl(d=3, h=20);
//       mechanical(visual_placements=[BOTTOM], visual_spin=210);
//     }
//
//
// Todo:
//   I hate visual_spin's use to get oscillatory annotations placed where I want them, and would much rather use visual_placements[0] and automatically rotate the correct number of degrees round the pivot. 
//
module mechanical(m=undef, visual_offset=undef, visual_color=undef, visual_alpha=undef, visual_placements=undef, visual_thickness=undef, visual_spin=undef, visual_limit=undef) {
    m__ = _first([m, $_mech]);
    log_fatal_unless(obj_is_obj(m__) && obj_toc_get_type(m__) == "Mech",
        "needs a $_mech variable defined to a Mech object");
    v_ = list_remove_values([
        (_defined(visual_offset)) ? ["visual_offset", visual_offset] : undef,
        (_defined(visual_color)) ? ["visual_color", visual_color] : undef,
        (_defined(visual_alpha)) ? ["visual_alpha", visual_alpha] : undef,
        (_defined(visual_placements)) ? ["visual_placements", visual_placements] : undef,
        (_defined(visual_thickness)) ? ["visual_thickness", visual_thickness] : undef,
        (_defined(visual_spin)) ? ["visual_spin", visual_spin] : undef,
        (_defined(visual_limit)) ? ["visual_limit", visual_limit] : undef,
        ], 
        [undef], 
        all=true
        );
    m_ = Mech(v_, mutate=m__);

    if (ok_to_annotate()) {
        log_fatal_unless(in_list(mech_type(m_), MECH_TYPES),
            ["unknown mechanical type", mech_type(m_), 
                "; Known types are:", MECH_TYPES
            ]);

        g = (_defined(mech_geom(m_)))
            ? mech_geom(m_)
            : Geom();

        g_derived_pivot = (is_list(mech_pivot(m_)))
            ? mech_pivot(m_) 
            : _find_anchor(mech_pivot(m_), ParentGeom(g))[1];

        m = (_defined(g))
            ? Mech(["geom", g,
                "pivot", g_derived_pivot
                ], mutate=m_)
            : log_fatal("No 'geom' attribute set and no '$parent_geom' available.");

        vcolor = mech_visual_color(m);
        valpha = mech_visual_alpha(m);

        color(vcolor, alpha=valpha * 2)
            if (mech_type(m) == "rotational") {
                placements = mech_visual_placements(m, default=[CENTER]);
                position(placements)
                    mech_rotational(m, orient=mech_axis(m), spin=mech_visual_spin(m));

            } else if (mech_type(m) == "oscillatory") {
                // placement is not central: placement matches the 
                // center of the arc, inward-facing, with the specified 
                // visual_placement attribute. 
                // the visual_offset is automatically offset both in the radius 
                // of the oscillation arc *and* in the attach() call.
                placements = mech_visual_placements(m, default=[CENTER]);
                log_info_unless(len(placements) == 1, 
                    ["exactly one placement setting is supported for oscillatory types; ",
                    "only", placements[0], "will be used."]);
                // calculate the distace from pivot (CENTER) to placements[0]. 
                // factor the offset (not sure which direction that goes) 
                // use the negative of that value for the overlap when attaching 
                //  ..... only, maybe don't do that.
                attach_offset = 0;
                position(placements[0])
                    mech_oscillatory(m, orient=mech_axis(m), spin=mech_visual_spin(m));

            } else if (mech_type(m) == "lateral") {
                placements = mech_visual_placements(m);
                position(placements)
                    move(mech_lateral_visual_offset_pos_by_placement(m, $attach_anchor))
                        mech_lateral(m, orient=mech_axis(m));

            } else if (mech_type(m) == "reciprocal") {
                placements = mech_visual_placements(m);
                position(placements)
                    move(mech_lateral_visual_offset_pos_by_placement(m, $attach_anchor))
                        mech_reciprocal(m, orient=mech_axis(m));
            }
    }
    children(); // BRAK: what children are we appending to any mechanical() annotation? Besides debugging anchor arrows for show_anchors()?
}


/// Subsection: Mechanical Module Support
///
/// Function: mech_lateral_visual_offset_pos_by_placement()
/// Synopsis: return a mat to use to move() a placement a set offset based on the parent's attaching anchor
function mech_lateral_visual_offset_pos_by_placement(m, attach_anchor) =
    let(
        anchor = attach_anchor[0],
        vo = mech_visual_offset(m),
        mat = move(anchor * vo, p=[0,0,0])
    )
    mat;


/// Module: mech_rotational()
/// Synopsis: produce a rotational mechanical annotation arrow: a stroke curved about an arc with a dotted line showing the rotational axis
/// Todo:
///   get rid of that ref to `$fn`
module mech_rotational(m, anchor=CENTER, spin=0, orient=UP) {
    // the radius of the arrow rotational is either the value of the Mech's pivot_radius, or the radius of the obj + (either the visual_offset attr or 5mm). 
    // the height of the arrow rotational is the radius of the obj, but shouldn't be higher than the object's height
    // the length (curved) of the arrow rotational is the limit attr of the Mech, or 360 otherwise
    geom = mech_geom(m);
    boundary = parent_geom_bounding_box(geom);

    r_ = (_defined_and_nonzero(mech_pivot_radius(m)))
        ? mech_pivot_radius(m)
        : (_defined_and_nonzero(geom_radius1(geom)))
            ? max([ geom_radius1(geom), geom_radius2(geom) ])
            : max([ boundary.x, boundary.y ]); // BRAK: need to not use .x/.y, should use dimension perpendicular to axis
    height = (_defined_and_nonzero(r_)) ? min([ r_ * 0.8, boundary.z * 0.8 ]) : 4;
    radius = (_defined_and_nonzero(r_)) ? r_ + mech_visual_offset(m) : undef;
    // choose the shorter of either the limit or visual_limit attributes: 
    degrees = min([mech_limit(m, default=360), mech_visual_limit(m, default=360), 360]);
    dir = mech_direction(m, default=["cw", "ccw"]);

    rotational_path = arc(32, angle=degrees, r=radius);
    axial_path = [down(boundary.z * 0.75, p=CENTER), up(boundary.z * 0.75, p=CENTER)];

    attachable(anchor, spin, orient, r=radius, h=height) {
        union() {
            stroke(
                rotational_path,
                width=mech_visual_thickness(m),
                endcap1=(in_list("cw", dir)) ? "arrow2" : undef,
                endcap2=(in_list("ccw", dir)) ? "arrow2" : undef,
                closed=false
                );
            dashed_stroke(
                axial_path,
                [8, 2, 3, 2, 3, 2],
                width=mech_visual_thickness(m) / 3,
                closed=false
                );
        }
        children();
    }
}

/// Module: mech_oscillatory()
/// Synopsis: like mech_rotational(), produce a rotational mechanical annotation arrow and axis, but explicitly set `direction` to `["cw", "ccw"]`
module mech_oscillatory(m, anchor=CENTER, spin=0, orient=UP) {
    mech_rotational(
        Mech([
                "direction", ["cw", "ccw"],
                "pivot_radius", mech_pivot_radius(m,
                                    default=path_length(
                                        path_from_center_to_vector(
                                            mech_visual_placements(m)[0],
                                            cp=mech_pivot(m)
                                            )
                                        )
                                    )
                ],
            mutate=m
            ),
        anchor=anchor,
        spin=spin,
        orient=orient
        );
}

/// Module: mech_lateral()
/// Synopsis: produce a movement arrow that travels in a straight line
/// Todo:
///   If axis is *not* UP, the geometry used may be (is) incorrect for generating an annotation arrow.
module mech_lateral(m, anchor=CENTER, spin=0, orient=UP) {
    dir = mech_direction(m);
    mvt = mech_visual_thickness(m);
    geom = mech_geom(m);
    axis = _first([ mech_axis(m), geom_axis(geom) ]);
    boundary = parent_geom_bounding_box(geom);

    default_len = max(boundary);
    lp_length = log_debug_assign( min([mech_limit(m, default=default_len), mech_visual_limit(m, default=default_len)]), "lp_length");
    lateral_path = [[-1 * (lp_length / 2), 0], [lp_length / 2, 0]];

    attachable(anchor, spin, orient, size=[mvt, mvt, lp_length]) {
        rot(from=RIGHT, to=dir[0]) // the stroke is a 2d path: rortate it from 'right' to whatever dir[0] is
            stroke(
                lateral_path,
                width=mvt,
                endcap1=(_defined(dir[1])) ? "arrow2" : undef,
                endcap2="arrow2",  // this is the dir[0] point, and it should always have an arrow cap
                closed=false
            );
        children();
    }
}

/// Module: mech_reciprocal()
/// Synopsis: thin named wrapper around mech_lateral(), to produce a movement arrow that travels in a straight line
module mech_reciprocal(m, anchor=CENTER, spin=0, orient=UP) {
    //... yup: we just re-use mech_lateral() and manually adjust the Mech's direction attribute:
    mech_lateral(m, anchor=anchor, spin=spin, orient=orient);
}


/// // Module: mech_attach()
/// // Synopsis: mechanically-aware version of BOSL2's `attach()`
/// // Usage:
/// //   [ATTACHABLE] mech_attach(from, to, m2) [CHILD];
/// //   [ATTACHABLE] mech_attach(from, to, m2, <overlap>, <norot=false>) [CHILD];
/// //
/// // Description:
/// //   Attaches a child to a parent object at an anchor point and orientation, while 
/// //   aware of the mechanical settings applied to both the parent and the child. 
/// //   .
/// //   All other behavior and side effects are that of `attach()`. 
/// //
/// // Arguments:
/// //   from = The vector, or name of the parent anchor point to attach to. No default
/// //   to = Optional name of the child anchor point.  If given, orients the child such that the named anchors align together rotationally. No default
/// //   m2 = The mechanical profile to be applied to the child object. No default
/// //   ---
/// //   overlap = Amount to sink child into the parent.  Equivalent to `down(X)` after the attach.  This defaults to the value in `$overlap`, which is `0` by default.
/// //   norot = If true, don't rotate children when attaching to the anchor point.  Only translate to the anchor point. Default: `false`
/// //
/// // Continues:
/// //   It is an error to use `mech_attach()` on a shape that has not a mechanical profile assigned to it: use `mech()` to apply a profile 
/// //   before attempting `mech_attach()`. 
/// //   It is an error to use `mech_attach()` for more than one child: I'm largely unclear why you'd want to, but mostly I haven't really 
/// //   thought through what will happen when you do that (so.. yeah. don't do that). 
/// //   It is *not* an error to specify two mechanically-aware objects that are incompatible, though maybe it should be; if you do, 
/// //   `mech_attach()` will permit the attachment, but will also flag it with a red error infoblock to highlight the issue in-scene.
/// //
/// // Example: attaching two mechanically aware columns meant to move laterally upwards:
/// //   mech("lateral", direction=UP)
/// //       cuboid([5, 5, 20]) {          
/// //           mechanical();
/// //           mech_attach(BOTTOM, TOP, mech("lateral", direction=UP), overlap=-0.1)
/// //               cuboid([5, 5, 20]) 
/// //                   mechanical();
/// //       }
/// //
/// // Example: same example as above, but these columns move in opposite directions, and flag a visual error:
/// //   mech("lateral", direction=UP)
/// //       cuboid([5, 5, 20]) {          
/// //           mechanical();
/// //           mech_attach(BOTTOM, TOP, mech("lateral", direction=DOWN), overlap=-0.1)
/// //               cuboid([5, 5, 20]) 
/// //                   mechanical();
/// //       }
/// //
/// // Todo:
/// //   decide if we want to incorporate `partno_attach()` style changes here
/// //   figure out multiple children. 
/// //
/// module mech_attach(from, to, m2, overlap, norot=false) {
///     m1 = $_mech;
///     log_fatal_unless(obj_is_obj(m1) && obj_toc_get_type(m1) == "Mech",
///         "needs a $_mech variable defined to a Mech object");
///     log_fatal_unless(obj_is_obj(m2) && obj_toc_get_type(m2) == "Mech",
///         "needs a m2 argument defined to a Mech object");
///     
///     log_fatal_unless($children == 1, 
///         "only one child attachment is supported for mech_attach()");
/// 
///     mechs_compatable = mech_compare(m1, m2);
/// 
///     assert($parent_geom != undef, "No object to attach to!");
///     overlap = (overlap!=undef)? overlap : $overlap;
///     anchors = (is_vector(from)||is_string(from))? [from] : from;
///     for ($idx = idx(anchors)) {
///         anchr = anchors[$idx];
///         anch = _find_anchor(anchr, $parent_geom);
///         two_d = _attach_geom_2d($parent_geom);
///         $attach_to = to;
///         $attach_anchor = anch;
///         $attach_norot = norot;
///         olap = two_d? [0,-overlap,0] : [0,0,-overlap];
///         $_mech = m2;
///         if (norot || (norm(anch[2]-UP)<1e-9 && anch[3]==0)) {
///             translate(anch[1]) translate(olap) children(0);
///         } else {
///             fromvec = two_d? BACK : UP;
///             translate(anch[1]) rot(anch[3],from=fromvec,to=anch[2]) translate(olap) children(0);
///         }
/// 
///         if (!mechs_compatable) 
///             attach(from, CENTER)
///                 infoblock_notok();
/// 
///     }
/// }
/// 
/// 
/// // Function: mech_compare()
/// // Synopsis: deterime if two given Mech objects are functionally compatible
/// // Usage:
/// //   bool = mech_compare(m1, m2);
/// //
/// // Description:
/// //   Given two Mech objects `m1`, `m2`, compare their compatability and return `true` if 
/// //   they are compatable, `false` otherwise. 
/// //   .
/// //   "compatible" here is carrying a lot of weight, and needs to be defined. I believe to answer, "are these two objects compatible?", we have to ask:
/// //   1. are the axis aligned and the type different? if they are, then NO
/// //   2. are the axis misaligned and type different? if they are, then MAYBE
/// //   3. are the axis aligned and the type the same? if they are, then YES (probably)
/// //   4. are the axis misaligned and the type different? if they are, then NO
/// //   . 
/// //    Further, if we have answered so far YES (aligned, type-same), then we ask:
/// //   .
/// //   5. are the two directions compatible? if they are not, then NO (this has a lot of possibilities: rotational cw vs ccw vs both; lateral up vs down vs both)
/// //   6. are there limits, and are they compatible? if they are not, then MAYBE
/// //   7. ... undoubtedly more stuff.
/// //
/// // Arguments:
/// //   m1 = An instantiated Mech object. No default
/// //   m2 = An instantiated Mech object. No default
/// //
/// // Continues:
/// //   It is an error to specify an `m1` or `m2` argument that is not a Mech object.
/// //
/// // Todo: 
/// //   Alignment checks need to include side-by-side attachments, like two disks that rotate each other on edge (cw & ccw)
/// //
/// function mech_compare(m1, m2) = 
///     assert(obj_is_obj(m1) && obj_toc_get_type(m1) == "Mech")
///     assert(obj_is_obj(m2) && obj_toc_get_type(m2) == "Mech")
///     let(
///         type_compat = _mech_compare_type(m1, m2),
///         axis_aligned = _mech_compare_axis(m1, m2),
///         dir_aligned = _mech_compare_dir(m1, m2),
///         tf = (
///             (type_compat && axis_aligned && dir_aligned) 
///             || (type_compat && mech_type(m1) == "rotational" && _mech_compare_rotational_type(m1, m2))
///             )
///     )
///     log_debug_assign(
///         tf,
///         [str("mechs are ",
///             (tf) ? "" : "not ",
///             "compatable:"),
///             str("type: ", mech_type(m1), "/", mech_type(m2)),
///             str("axis: ", mech_axis(m1), "/", mech_axis(m2)),
///             str("dir: ", mech_direction(m1), "/", mech_direction(m2)) 
///         ]);
/// 
/// /// Function: _mech_compare_rotational_type()
/// /// Description:
/// ///   Given two rotational Mech objects that may or may not have aligned axis, 
/// ///   normalize the two axis and do a direction comparison
/// function _mech_compare_rotational_type(m1, m2) =
///     let(
///         // see if the two axis are compatable, either mirrored or normalized. 
///         // if the axis are identical, do a straight comparison of the mech's direction attributes. 
///         // if the axis are compatible, then reverse m2's direction attributes, and compare them against m1.
///         v = (mech_axis(m1) == mech_axis(m2))
///             ? (mech_direction(m1) == mech_direction(m2))
///             : (_mech_compare_axis(m1, m2))
///                 ? (mech_direction(m1) == _mech_flip_directions_rotational(m2))
///                 : false
///     )
///     v;
/// 
/// /// Function: _mech_flip_directions_rotational()
/// /// Description:
/// ///   Given a Mech object, return its direction attribute 
/// ///   as a list, but each element is the inverse of its value:
/// ///   "cw" becomes "ccw", and "ccw" becomes "cw". Undef values 
/// ///   remain undefined. 
/// function _mech_flip_directions_rotational(m) =
///     let(
///         d = mech_directions(m),
///         d0_f = (d[0] == "cw") ? "ccw" : "cw",
///         d1_f = (defined(d[1]))
///             ? (d[1] == "cw") ? "ccw" : "cw"
///             : undef
///     )
///     [d0_f, d1_f];
/// 
/// /// Function: _mech_compare_type()
/// /// Description:
/// ///   Given two Mech objects, compare their types for compatability and return true if the 
/// ///   types are _generally_ compatible, false otherwise.
/// function _mech_compare_type(m1, m2) =
///     let(
///         m1_t = mech_type(m1),
///         m2_t = mech_type(m2),
///         m1_type_class = (in_list(m1_t, select(MECH_TYPES, [0, 1]))) ? "rot" : "lat",
///         m2_type_class = (in_list(m2_t, select(MECH_TYPES, [0, 1]))) ? "rot" : "lat"
///     )
///     m1_t == m2_t || m1_type_class == m2_type_class;
/// 
/// /// Function: _mech_compare_axis()
/// /// Description:
/// ///   Given two Mech objects, compare their axes, returning true if 
/// ///   the axes are equal, false otherwise.
/// function _mech_compare_axis(m1, m2) = 
///     let(
///         m1_a = mech_axis(m1),
///         m2_a = mech_axis(m2),
///         are_eq = (m1_a == m2_a),
///         are_mirror_eq = approx(m1_a, mirror(m2_a, p=m2_a))
///     )
///     ( are_eq || are_mirror_eq );
/// 
/// /// Function: _mech_compare_dir()
/// /// Description:
/// ///   Given two Mech objects, return true if their direction attributes are 
/// ///   equal, or if one direction is "both"; false otherwise. 
/// function _mech_compare_dir(m1, m2) =
///     let( 
///         m1_d = mech_direction(m1), 
///         m2_d = mech_direction(m2),
///         //
///         dirs_are_equal = ( ( m1_d == m2_d || approx(m1_d, m2_d) ) || ( m1_d == reverse(m2_d) || approx(m1_d, reverse(m2_d)) ) ),
///         //
///         dirs_overlap = ( len(set_intersection(m1_d, m2_d)) > 0)
///     )
///     (dirs_are_equal || dirs_overlap);
/// 


/// Section: Mech Object 
///   The Mech Object uses openscad_objects to manage mechanical attributes for shapes and models. A singular Mech object may be applied to 
///   a model; that object will be inherited by all that model's children, until the Mech object is replaced or cleared. 
///
/// Subsection: Object Constants
///
/// Constant: MECH_TYPES
/// Synopsis: known, supported mechanical annotation types
/// Description:
///   A list of known, supported mechanical annotation types.
///   *Note:* These types are position-dependent within `mech_attach()`: their placement is significant.
///
MECH_TYPES = ["rotational", "oscillatory", "lateral", "reciprocal"];

/// Constant: Mech_attributes
/// Synopsis: attribute definition list for Mech objects
/// Description:
///   A list of all available `Mech` attributes.
/// Attributes:
///   type = s = Type of movement, one of `MECH_TYPES`. No default
///   direction = s = Direction of movement for this annotation. The value is `type` dependent: for `rotational` and `oscillatory` types, may be one of `cw` (for clockwise), `ccw`, or `both`; for `lateral` and `reciprocal` types, may be one of `up`, `down`, or `both`. No default
///   limit = i = Specifies a limit to how far the mechanical movement extends; may be degrees of rotation, or units of motion. No default
///   geom = l = Holds the geometry for the shape involved in the movement. No default
///   axis = l = Axis vector, detailing the central axis for this mechanical movement. Default: `UP`
///   pivot = l = Sets the pivot position for an oscillatory pivot mechanism. Default: `CENTER`
///   pivot_radius = i = Sets the radius for an oscillatory pivot mechanism. No default
///   visual_offset = i = For visual annotations, sets an offset used for movement annotations. Default: `2`
///   visual_color = s = For visual annotations, sets the annotation shape color. Default: `blue`
///   visual_alpha = i = For visual annotations, sets the transparency of the shapes. Default: `0.2`
///   visual_placements = l = For visual annotations, sets the placement location relative to the shape being annotated. Default: `[RIGHT]` (as in, a list with a single element of `RIGHT` within it)
///   visual_thickness = i = For visual annotations, sets the thickness of the annotating arrow shape. Default: `0.5`
///   visual_spin = i = For visual annotations, rotates the produced model on the z-axis by this many degrees before placement. Default: `0`
///   visual_limit = i = For visual annotations, restricts the size of the annotation as though `limit` had been applied. Default: `0`
/// 
Mech_attributes = [
    "type=s",       // one of: rotational, oscillating, recipricol, or linear
    "direction=l",  // lateral is a list of vectors; rotational is a list of cw, ccw
    "limit=i",
    ["geom", "l", []],
    ["axis", "l", UP],
    ["pivot", "l", CENTER],
    "pivot_radius=i",
    "visual_offset=i=2",
    "visual_color=s=blue", 
    "visual_alpha=i=0.2",
    ["visual_placements", "l", [RIGHT]],
    "visual_thickness=i=2",
    "visual_spin=i",
    "visual_limit=i",
    ];

/// Subsection: Object Creation
///
/// Function: Mech()
/// Synopsis: construct and return a new Mech object
/// Description:
///   Creates a new `mech` object given a variable list of `[attribute, value]` lists. 
///   Attribute pairs can be in any order. Unspecified attributes will be set to `undef`. 
///   `Mech()` returns a new list that should be treated as an opaque object.
///   .
///   Optionally, an existing `mech` object can be provided via the `mutate` argument: that 
///   existing `mech` will be used as the original set of object attribute values, and any 
///   new values provided in `vlist` will take precedence.
/// Usage:
///   mech = Mech(vlist);
///   mech = Mech(vlist, mutate=mech);
/// Arguments:
///   vlist = Variable list of attributes and values: `[ ["type", "rotational"], ["limit", 50] ]`. 
///   ---
///   mutate = An existing `mech` object on which to pre-set base values. Default: `[]`
/// See also: mech()
/// 
function Mech(vlist=[], mutate=[]) = Object("Mech", Mech_attributes, vlist=vlist, mutate=mutate);

/// Subsection: Mech Object Attribute Accessor Functions
///   Each of the attributes listed in `Mech_attributes` has an accessor built 
///   for it. For example, a Mech's `type` is accessed via 
///   `mech_type()`. These attribute-specific functions are 
///   convienence, and all have the same form. They are listed below, and all have 
///   the same function definition as `mech_type()`, also documented below.
///
/// Function: mech_type()
/// Synopsis: Mech object accessor for `type`
/// Description: 
///   Mutatable object accessor specific to the `type` attribute. 
/// Usage:
///   type = mech_type(mech, <default=undef>);
///   new_mech = mech_type(mech, <nv=undef>);
/// Arguments:
///   mech = A strut object
///   ---
///   default = If provided, and if there is no existing value for `type` in the object `mech`, returns the value of `default` instead. 
///   nv = If provided, `mech_type()` will update the value of the `type` attribute and return a new Mech object. *The existing Mech object is unmodified.*
///
function mech_type(mech, default=undef, nv=undef) = obj_accessor(mech, "type", default=default, nv=nv);
function mech_direction(mech, default=undef, nv=undef) = obj_accessor(mech, "direction", default=default, nv=nv);
function mech_limit(mech, default=undef, nv=undef) = obj_accessor(mech, "limit", default=default, nv=nv);
function mech_geom(mech, default=undef, nv=undef) = obj_accessor(mech, "geom", default=default, nv=nv);
function mech_axis(mech, default=undef, nv=undef) = obj_accessor(mech, "axis", default=default, nv=nv);
function mech_pivot(mech, default=undef, nv=undef) = obj_accessor(mech, "pivot", default=default, nv=nv);
function mech_pivot_radius(mech, default=undef, nv=undef) = obj_accessor(mech, "pivot_radius", default=default, nv=nv);
function mech_visual_offset(mech, default=undef, nv=undef) = obj_accessor(mech, "visual_offset", default=default, nv=nv);
function mech_visual_color(mech, default=undef, nv=undef) = obj_accessor(mech, "visual_color", default=default, nv=nv);
function mech_visual_alpha(mech, default=undef, nv=undef) = obj_accessor(mech, "visual_alpha", default=default, nv=nv);
function mech_visual_placements(mech, default=undef, nv=undef) = obj_accessor(mech, "visual_placements", default=default, nv=nv);
function mech_visual_thickness(mech, default=undef, nv=undef) = obj_accessor(mech, "visual_thickness", default=default, nv=nv);
function mech_visual_spin(mech, default=undef, nv=undef) = obj_accessor(mech, "visual_spin", default=default, nv=nv);
function mech_visual_limit(mech, default=undef, nv=undef) = obj_accessor(mech, "visual_limit", default=default, nv=nv);


