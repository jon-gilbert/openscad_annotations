// LibFile: dimensioning.scad
//   Methods for describing dimensioning elements around and against
//   simple 3D models. The attempt is made to be as frictionless 
//   as possible for BOSL2 primitives, and equally easy to implement 
//   for non-BOSL2 primitives and other custom models. 
//
// FileSummary: dimensioning methods and functions
// Includes:
//   include <507common/dimensioning.scad>
//

LOG_LEVEL = 2;
include <openscad_annotations/bosl2_geometry.scad>
include <attachable_text3d.scad>
include <logging.scad>

$_annotate_dimensions = [];

// Section: Modules
//
// Function&Module: dimension()
// Synopsis: Set or augment a shape's list of applicable dimensions
// Usage: as a function
//   dimension = dimension(dim);
//   dimension = dimension(dim, <context=undef>, <tolerance=undef>, <units=undef> ...);
//   dimension = dimension(Dimension);
// Usage: as a module
//   dimension(dim) CHILDREN;
//   dimension(dim, <context=undef>, <tolerance=undef>, <units=undef> ...) CHILDREN;
//   dimension(Dimension) CHILDREN;
// Description:
//   As a function, `dimension()` returns a Dimension object `dimension` that describes a measured dimension. 
//   Arguments passed to `dimension()` are bounds-checked for sanity and suitable defaults are applied before 
//   calling `Dimension()` to obtain the returned `dimension` object. The returned object is suitable for use 
//   as applied to a shape via the locally-scoped `$_annotate_dimension` variable, or by reusing it 
//   in a subsequent module call to `dimension()`, or as passed directly to `measure()`. 
//   .
//   As a module, `dimension()` applies a set of given dimension attributes to children of the `dimension()` 
//   module call. This and other dimensions can be later accessed, queried, or rendered into the 3D scene 
//   with `measure()`. If one or more Dimension objects are already applied in the current 
//   hierarchy, `dimension()` will add to that list. 
// Arguments:
//   dim = The dimension value. No default.
//   Dimension = An already-instantiated Dimension object. No default.
//   ---
//   context = Additional context to present underneath or alongside the dimension value. No default.
//   tolerance = A value of tolerance for the specified dimension. No default.
//   units = A string to be used as the dimension units, if specified (eg, `"mm"`, `"ft"`). No default.
//   isdiam = If set to `true`, the dimension will be considered a diameter, and have its labels and placements adjusted accordingly. Default: `false`
//   israd = If set to `true`, the dimension will be considered a radius, and have its labels and placements adjusted. Default: `false`
//   isdeg = If set to `true`, the dimension will be considered an angle in degrees, and have its label adjusted. Default: `false`
//   isflyout = If set to `true`, the dimension will be treated as a flyout. Default: `false`
//   ext = The length of the extension lines (and, the distance from the centerline of the model this dimension should be presented). No default.
//   aso = A list tuple of three settings: the position anchor the Dimension should attach to (*on the parent*); a number of degrees to spin the Dimension model before positioning it onto the parent; and, the orientation to use for the Dimension model before positioning or spinning. Default: `[FWD+BOTTOM, 0, UP]`
//   font_size = Size of the font the dimension and context will be presented in. Default: `2`
//   font_thickness = The thickness (or height) the font will be produced at. Default: `0.5`
//   color = Name of color to render dimensions, their lines & extensions, and context in. Default: `black`
//   pos = Absolute position relative to the shape at which the dimension should be placed. Considered deprecated in favor of `aso`. No default.
//
// Continues:
//   It is not an error to invoke `dimension()` as a function without either a valid `dim` value, or an instatiated `Dimension` object, 
//   however `dimension()` will return an undef value in this case, and the caller should check for that.
//   It is also not an error to invoke `dimension()` as a module in the same way: calling `dimension()` as a module when there is no 
//   valid `dim` value or `Dimension` object won't change any existing dimensions, nor will it change the list of dimensions in 
//   the current hierarchy, nor will it inhibit processing the child modules yet to be processed. 
//
// Todo:
//   fully support 2D shapes
//
// Example(NORENDER): creating a basic Dimension object:
//   d = dimension(10);
//   echo(obj_debug_obj(d));
//   // yields to the console:
//   // ECHO: "0: _toc_: Dimension
//   // 1: dim (i: undef): 10
//   // 2: context (s: undef): undef
//   // 3: tolerance (i: undef): undef
//   // ...
// Example: applying a dimension to a basic 3D shape: note that there's no appreciable change to the cube:
//   dimension(10)
//      cube(10, center=true);
// Example: applying a dimension to a basic 3D shape: same example as above, but now `echo()` is called as a child to the `cube()`, displaying the Dimension object:
//   dimension(10)
//       cube(10, center=true)
//           echo(obj_list_debug_obj($_annotate_dimensions));
//   // yields to the console:
//   // ECHO: ["0: _toc_: Dimension
//   // 1: dim (i: undef): 10
//   // 2: context (s: undef): undef
//   // 3: tolerance (i: undef): undef
//   // ...
// Example: applying multiple dimensions to a basic 3D shape, one `dimension()` call at a time: note the second `Dimension` object with the `context` attribute set:
//   dimension(10)
//       dimension(20, context="additional")
//           cube(10, center=true)
//               echo(obj_list_debug_obj($_annotate_dimensions));
//   // yields to the console:
//   // ECHO: ["0: _toc_: Dimension
//   // 1: dim (i: undef): 10
//   // 2: context (s: undef): undef
//   // 3: tolerance (i: undef): undef
//   // ...
//   // 13: color (s: black): undef
//   // 14: pos (l: []): []", "0: _toc_: Dimension
//   // 1: dim (i: undef): 20
//   // 2: context (s: undef): additional
//   // 3: tolerance (i: undef): undef
//   // ...
// Example: applying an invalid dimension to a basic 3D shape: note the empty list, instead of Dimension objects:
//   dimension(undef)
//       cube(10, center=true)
//           echo($_annotate_dimensions);
//   // yields to the console:
//   // ECHO: []
//
function dimension(dim_or_obj, context=undef, tolerance=undef, units=undef, isdiam=false, israd=false, isdeg=false, isflyout=false, ext=undef, aso=undef, aso_post_translate=undef, font_size=undef, font_thickness=undef, color=undef, pos=undef) =
    let(
        dim = (_defined(dim_or_obj) && !obj_is_obj(dim_or_obj))
            ? dim_or_obj
            : undef,
        Dimobj = (_defined(dim_or_obj) && obj_is_obj(dim_or_obj) && obj_get_type(dim_or_obj) == "Dimension")
            ? dim_or_obj
            : undef
    )
    (_defined(Dimobj) && obj_is_obj(Dimobj))
        ? Dimobj
        : (_defined(dim))
            ? Dimension(["dim", dim, "context", context, "tolerance", tolerance, "units", units, 
                "isdiam", isdiam, "israd", israd, "isdeg", isdeg, "isflyout", isflyout, "ext", ext, "aso", aso, 
                "aso_post_translate", aso_post_translate, "font_size", font_size, "font_thickness", font_thickness, 
                "color", color, "pos", pos])
            : undef;


module dimension(dim_or_obj, context=undef, tolerance=undef, units=undef, isdiam=false, israd=false, isdeg=false, isflyout=false, ext=undef, aso=undef, aso_post_translate=undef, font_size=undef, font_thickness=undef, color=undef, pos=undef) {
    d = dimension(dim_or_obj, context=context, tolerance=tolerance, units=units, 
        isdiam=isdiam, israd=israd, isdeg=isdeg, isflyout=isflyout, ext=ext, aso=aso, aso_post_translate=aso_post_translate, 
        font_size=font_size, font_thickness=font_thickness, color=color, pos=pos);
    // assign, or extend, $_annotate_dimensions with `d`. 
    // if there is no valid Dimension object `d`, do not augment the $_annotate_dimensions list.
    $_annotate_dimensions = (_defined(d) && obj_is_obj(d))
        ? (_defined($_annotate_dimensions))
            ? concat($_annotate_dimensions, [d])
            : [d]
        : $_annotate_dimensions;
    // ...and then continue processing the hierarchy:
    children();
}


// Module: measure()
// Synopsis: Create dimension annotations around an attachable 3D shape, or "measure a shape"
// Usage:
//   [PARENT] measure();
//   [PARENT] measure(<dimensions=[]>, <bosl2_dims=true>);
//
// Description:
//   `measure()` provides dimensioning elements around a 3D model. 
//   The measurements and dimensions are intended to mimic those seen in engineering diagrams, to 
//   give a sense of scale and scope to models. *The results of measure() are not intended to support 
//   precise engineering use-cases.*
//   .
//   Dimensioning elements 
//   may be provided in one of three ways: as an argument, the `dimensions` list can specify zero or 
//   more Dimension objects; as a special inherited variable `$_annotate_dimensions`, which is a list 
//   containing one or more Dimension objects in its first element, as set by `dimension()`; and, as native BOSL2  
//   geometry located in `$parent_geom`, which defines outer boundaries of models that are 
//   attachable. 
//   .
//   Base 507common objects that can support `obj()` should provide Dimension objects via that module. 
//   .
//   If the Dimension object has a `pos` attribute set to a value, the resulting dimension line will be 
//   moved to that position relative to `[0,0,0]` in the context of the parent shape `[PARENT]`.
//   .
//   If there is no `pos` attribute set, the dimension lines are arranged around an attachable model `[PARENT]` according to the Dimension's 
//   `aso` attribute (short for "attach-point, spin, orient"). The Dimension is modeled into 
//   a dimension line, then spun and oriented, and *then* positioned to the `attach-point` of `aso`.
//   .
//   Dimension extenders `ext` are automatically adjusted to accomodate all the Dimensions that are 
//   placed at that anchor-point; Dimension objects are sorted by their dimension `dim` attribute, 
//   with the smallest values closest to the model, and the largest values furthest away, providing 
//   a nested set of dimensions that hopefully do not overlap. Multiple dimensions of the same `dim` value 
//   will be displayed in no specific order to each other.
//   .
//   Calling `measure()` as a child to a model that neither declares any Dimensions nor 
//   provides any `$parent_geom` geometry isn't an error, and shouldn't affect the 
//   creation or rendering of the model.
//
// Arguments:
//   ---
//   dimensions = A list of Dimension objects. The Dimensions can be provided in any order. Default: `[]`
//   bosl2_dims = If set to `false`, the `$parent_geom` geometry produced by BOSL2 won't be displayed as a measurement. Default: `true`
//
// Continues:
//   Though this will work with any BOSL2 3D attachable model, it currently will not work with any 2D models (eg, `circle()`).
//
// Continues:
//   Explain: Why do we use `aso` and its convoluted flipping and positioning and not just anchor?
//
// Todo:
//   fully support 2D shapes
//   Better support needed for: pie slice, wedge, onion, teardrop, vnf-extent, tube, torus: they have inside or extended aspects of their shape that are not represented by `$parent_geom`
//
// Example: basic cuboid() measurement:
//   cuboid(15)
//       measure();
// 
// Example: basic prismoid measurement:
//   prismoid(size1=[25,30], size2=[12,15], h=15)
//       measure();
// 
// Example: basic VNF-extent type measurement: BOSL2's `octohedron()` produces its shape as a VNF, and `measure()` can't yet fully realize VNF's complexity, so it falls back to measuring a simple bounding box around the shape:
//   octahedron(size=20)
//       measure();
// 
// Example: basic rect_tube measurement. Note there is no internal dimension measurement produced:
//   rect_tube(size=10, wall=2, h=15)
//       measure();
// 
// Example: basic wedge measurement. Note it's z-axis placement isn't ideal, but still functional:
//   wedge([20, 40, 15])
//       measure();
// 
// Example: basic cylinder measurement:
//   cyl(d=20, h=15)
//       measure();
// 
// Example: cylinder with two different diameter settings:
//   cyl(d=20, d2=10, h=15)
//       measure();
//
// Example: same cylinder as above with two different diameter settings, but specified with radii (`r`, `r2`) instead of diameters (`d`, `d2`):
//   cyl(r=10, r2=5, h=15)
//       measure();
// 
// Example: same cylinder as above again, but with `xcyl()`, which has it oriented to the right:
//   xcyl(l=15, d=20, d2=10)
//       measure();
// 
// Example: basic tube measurement. Note there is no internal dimension measurement produced:
//   tube(or=15, wall=4, h=15)
//       measure();
// 
// Example: basic pie slice: the geometry dimensions are accurate, however there's not enough information provided to show the measure of the angle in the shape:
//   pie_slice(ang=45, l=20, r=10)
//       measure();
//
// Example: to fully illustrate the angle shown with `pie_slice()`, a flyout can be slapped right on top:
//   dimension(45, isdeg=true, isflyout=true, aso=[TOP])
//       pie_slice(ang=45, l=20, r=10)
//           measure();
// 
// Example: basic sphere measurement:
//   sphere(10)
//       measure();
// 
// Example: basic torus measurement:
//   torus(id=15, od=20)
//       measure();
// 
// Example: basic teardrop measurement. Note that while the radius and thickness are accurate, there is not measurement data made available for the point:
//   teardrop(r=15, h=10, ang=30)
//       measure();
// 
// Example: basic teardrop measurement: like with `pie_slice()` above, a flyout can be applied to note what the teardrop's angle is:
//   dimension(30, isdeg=true, isflyout=true, aso=[RIGHT+TOP])
//       teardrop(r=15, h=10, ang=30)
//           measure();
// 
// Example: basic onion shape measurement. Note that while the diameter is accurate, there is not measurement data made available for the point:
//   onion(r=15, ang=30)
//       measure();
//
// Example: dimensions can be pre-calculated and passed directly to `measure()` when it's not feasible to use `dimension()` to set them within the hierarchy:
//   d1 = dimension(15, units="mm", context="cuboid()");
//   cuboid(15)
//        measure(dimensions=[d1]);
//
// Example: built-in BOSL2 dimensions can be prevented from being displayed with the `bosl2_dims` argument (of course, they're still there; `measure()` simply ignores them):
//   dimension(15, context="this is the only shown measurement")
//       cuboid(15)
//           measure(bosl2_dims=false);
//
// Example: dimensions can be displayed as flyouts, by setting `isflyout` to `true`:
//   dimension(15^3, context="volume", units="mm^3", isflyout=true, aso=[TOP])
//       cuboid(15)
//           measure();
//
// Example: flyouts can be positioned at any arbitrary position:
//   dimension("X", context="marks the spot", isflyout=true, pos=[-3, 7.5, 7.5])
//       cuboid(15)
//           measure();
//
// Example: flyouts can be positioned at any standard cardinal attachment point:
//   dimension("X", context="marks the spot", isflyout=true, aso=[FWD+LEFT+TOP])
//       cuboid(15)
//           measure();
//
// Example: both line and flyout dimensions can be mixed and matched when assigning to a shape, and can be applied in any order, and `measure()` will stack them in the right order:
//   dimension(2.02)
//       dimension(1.2)
//           dimension(1.62, aso=[RIGHT+TOP, 90, UP])
//               dimension(11.0)
//                   dimension(1.6, aso=[RIGHT+BOTTOM, 90, UP])
//                       dimension(60, isflyout=true, isdeg=true, pos=[0,0,10])
//                           cuboid(20)
//                               measure(); 
//
//
module measure(dimensions=[], bosl2_dims=true) {
    // assemble dimensions from all possible sources into a single list.
    // ignore list elements that are undefined, or are not objects.
    // BRAK: do we need to ref parent_geom here at all?
    geometry_dimensions = (bosl2_dims && _defined($parent_geom)) ? convert_parent_geom_to_dimensions($parent_geom) : [];
    ad_ = concat(geometry_dimensions, dimensions, $_annotate_dimensions);
    dimensions_and_flyouts = [ for(t=ad_) if (_defined(t) && obj_is_obj(t)) t ];

    // split that list out into dimensions that are measurements, and dimensions that are flyouts:
    dims = obj_select_by_attr_value(dimensions_and_flyouts, "isflyout", false);
    flyouts = obj_select_by_attr_value(dimensions_and_flyouts, "isflyout", true);

    // re-group the dimensions, organized by their `aso` attribute:
    regrouped_dims = obj_regroup_list_by_attr(dims, "aso");
    
    // process each group of dims: the dimensions are grouped 
    // by their `aso` attribute; each group is sorted 
    // ascendingly by the `dim` attribute, and each line extension is increased 
    // according to the order in which the dimension is sorted.
    for (group=regrouped_dims) {
        sorted_dimensions = obj_sort_by_attribute(group, "dim");
        for (i=idx(sorted_dimensions)) {
            dimension = dim_ext(
                sorted_dimensions[i],
                nv=sum([ 
                    i * (dim_font_size(sorted_dimensions[i]) * 4), 
                    dim_font_size(sorted_dimensions[i]) * 2 
                    ]) 
                );
            if (_defined(dim_pos(dimension))) {
                move(dim_pos(dimension))
                    dimension_line_extended(dimension, anchor=BACK);
            } else {
                position(dim_aso(dimension)[0])
                    dimension_line_extended(dimension, anchor=BACK);
            }
        }
    }

    // process all the Dimension flyout objects: model, then
    // position each flyout received:
    for (flyout=flyouts) {
        if (_defined(dim_pos(flyout))) {
            move(dim_pos(flyout))
                dimension_flyout(flyout);
        } else {
            position(dim_aso(flyout)[0])
                dimension_flyout(flyout);
        }
    }

    children();
}


/// Module: dimension_line()
/// Usage:
///   dimension_line(dl);
///   dimension_line(dl, <anchor=CENTER>, <spin=0>, <orient=UP>);
///
/// Description:
///   Given a Dimension object, construct a dimension line. The line is produced along the X-axis, at the length of the dimension attribute `dim`.
///   The line is tipped with arrowheads, ending at the outer boundary of the of dimension. Centered on the line, oriented upwards, is the
///   dimension value. If the dimension line is shorter than the text to be rendered, the text will be placed underneath the
///   line (relative to the upwards-facing view). Orientation, and spin can be specified with the `spin` and `orient` arguments as 
///   normal, but they can also be set through the `aso` object attribute. 
///   If the Dimension object has `aso_post_translate` set, the line will be adjusted by that 
///   vector after construction. 
///   .
///   The attributes `isdiam`, `israd`, and `isdeg` will all affect the dimension text, adding elements to remove
///   ambiguity of the dimension. An optional `units` attribute if set will be suffixed to the dimension.
///   See `dimension_text_formatting()`, below, for additional information on how the dimension `dim` attribute
///   can be adjusted.
///   If the context attribute `context` is set in the Dimension object, that additional context will be produced
///   underneath the dimension; note that the `context` content will remain unchanged, unlike the `dim` dimension content.
///   The font size and thickness of the labels come from the `font_size` and `font_thickness` attributes.
///   .
///   The color of the dimension line and the dimension textcomes from the Dimension object `color`.
///   .
///
/// Arguments:
///   dl = A Dimension object
///   ---
///   anchor = Translate so anchor point is at origin `[0,0,0]`. Default: `CENTER`
///   spin = Rotate this many degrees around the Z axis after anchoring. Default: `0`
///   orient = Vector direction to which the model should point after spin. Default: `UP`
///
/// Continues:
///   The attachment bounding of the dimension line is approximate. It will *always* be approximate, owing to the
///   vagarities of text sizing produced by `attachable_text3d()`. This means, apart from the `LEFT`, `RIGHT`, and `CENTER`
///   positions, you cannot ever fully trust the built-in cardinal attachment points (though it will be close enough for
///   most purposes). Do not waste time trying to fix this today.
///
/// Named Anchors:
///   dimension-left-fwd = The left-hand endpoint of the dimension line, pointing forwards
///   dimension-left-back = The left-hand endpoint of the dimension line, pointing backwards
///   dimension-left-up = The left-hand endpoint of the dimension line, pointing upwards
///   dimension-left-down = The left-hand endpoint of the dimension line, pointing downwards
///   dimension-right-fwd = The right-hand endpoint of the dimension line, pointing forwards
///   dimension-right-back = The right-hand endpoint of the dimension line, pointing backwards
///   dimension-right-up = The right-hand endpoint of the dimension line, pointing upwards
///   dimension-right-down = The right-hand endpoint of the dimension line, pointing downwards
/// Figure: Available named anchors
///   include <507common/base.scad>
///   expose_anchors() dimension_line(Dimension(["dim", 10])) show_anchors(std=false, s=3);
///
/// Example:
///   dimension_line(Dimension(["dim", 10]));
///
/// Example:
///   dimension_line(Dimension(["dim", 20]));
///
/// Example: `dimension_line()` will reposition text and dimension pointers as needed, based on the size of the dimension, the size of the arrows, and the font size:
///   left(10) back(5)
///       dimension_line( Dimension(["dim", 0.5]) );
///   left(10) fwd(5)
///       dimension_line( Dimension(["dim", 3]) );
///   right(10) back(5)
///       dimension_line( Dimension(["dim", 11]) );
///   right(10) fwd(5)
///       dimension_line( Dimension(["dim", 14]) );
///
/// Example: providing additional context to a dimension
///   dimension_line(Dimension(["dim", 20, 
///      "context", "length"]));
///
/// Example: a dimension for a diameter, using `isdiam`, along with `units`:
///   dimension_line(Dimension(["dim", 20, 
///      "isdiam", true, 
///      "units", "mm"]));
///
module dimension_line(dl, anchor=CENTER, spin=0, orient=undef) {
    dimension = dim_dim(dl);
    font_size = dim_font_size(dl);
    font_thickness = dim_font_thickness(dl);
    color = dim_color(dl);
    units = dim_units(dl);
    isdiam = dim_isdiam(dl);
    context = dim_context(dl);
    aso = dim_aso(dl);
    spin_ = _first_nonzero([ spin, aso[1] ]);
    orient_ = _first([ orient, aso[2] ]);
    direction = "back";

    dim_ts = dimensional_text_and_bounding(
        dimension_text_formatting(dl),
        font_size,
        font_thickness);
    text = dim_ts[0];
    text_b = dim_ts[1];

    context_ts = (_defined(context))
        ? dimensional_text_and_bounding(context, font_size, font_thickness)
        : [undef, [0,0,0]];
    context_ts_b = context_ts[1];

    arrowhead_width = DIM_LINE_WIDTH * 2;
    arrowhead_height = DIM_LINE_WIDTH * 2 * 3;

    arr_lead = arrowhead_height + 2;
    style = (sum([ arr_lead * 2, text_b.x ]) < dimension)
        ? "inline"  // all three elements fit within the dimension; style is "inline" ; <-DIM->
        : ((arr_lead * 2) < dimension)
            ? "below-inline"  // arrows connect to each other, label is below them; style is "below-inline" ; <-->
            : (text_b.x < dimension)
                ? "outline"  // arrows outside the dimension, label within; style is "outline" ; ->DIM<-
                : "below-outline"; // arrows outside the dim, label below the space; style is "below-outline" ; -><-

    bounding_size = (style == "inline")
        ? [ dimension,
            sum([ max([ text_b.y, arrowhead_width ]), context_ts_b.y ]),
            max([ text_b.z, arrowhead_width, context_ts_b.z ])
            ]
        : (style == "below-inline")
            ? [ max([ dimension, text_b.x, context_ts_b.x ]),
                sum([ arrowhead_width, text_b.y, context_ts_b.y ]),
                max([ text_b.z, arrowhead_width, context_ts_b.z ])
                ]
            : (style == "outline")
                ? [ sum([ dimension, arr_lead * 2 ]),
                    sum([ max([ arrowhead_width, text_b.y ]), context_ts_b.y ]),
                    max([ text_b.z, arrowhead_width, context_ts_b.z ])
                    ]
                : (style == "below-outline")
                    ? [ sum([ dimension, arr_lead * 2 ]),
                        sum([ arrowhead_width, text_b.y, context_ts_b.y ]),
                        max([ text_b.z, arrowhead_width, context_ts_b.z ])
                        ]
                    : log_fatal(["Unknown style:", style]);

    // NOTE: the named anchors ARE valid and positioned correctly.
    anchors = [
        named_anchor("extension-left-fwd",   apply(left(dimension/2),  CENTER), FWD, 0),
        named_anchor("extension-left-back",  apply(left(dimension/2),  CENTER), BACK, 0),
        named_anchor("extension-left-up",    apply(left(dimension/2),  CENTER), UP, 0),
        named_anchor("extension-left-down",  apply(left(dimension/2),  CENTER), DOWN, 0),
        named_anchor("extension-right-fwd",  apply(right(dimension/2), CENTER), FWD, 0),
        named_anchor("extension-right-back", apply(right(dimension/2), CENTER), BACK, 0),
        named_anchor("extension-right-up",   apply(right(dimension/2), CENTER), UP, 0),
        named_anchor("extension-right-down", apply(right(dimension/2), CENTER), DOWN, 0),
        ];

    translate(dim_aso_post_translate(dl))
    attachable(anchor, spin_, orient_, size=bounding_size, anchors=anchors) {
        color(color, alpha=DIM_COLOR_ALPHA)
            if (style == "inline") {
                _dimension_line_inline(dl, text_b, text, font_size, font_thickness, context_ts[0]);
            } else if (style == "below-inline") {
                _dimension_line_below_inline(dl, text_b, text, font_size, font_thickness, context_ts[0]);
            } else if (style == "outline") {
                _dimension_line_outline(dl, text_b, text, font_size, font_thickness, context_ts[0]);
            } else if (style == "below-outline") {
                _dimension_line_below_outline(dl, text_b, text, font_size, font_thickness, context_ts[0]);
            } else {
                log_fatal(["Unknown style:", style]);
            }
        children();
    }
}

/// Module: _dimension_line_inline()
/// Description:
///    <--- DIM --->
module _dimension_line_inline(dl, bounds, label, font_size, h, context=undef) {
    dim = dim_dim(dl);
    diff("_dli_rem", "_dli_keep") {
        tag("_dli_rem")
            cube([bounds.x + 1.5, bounds.y, bounds.z], anchor=CENTER);
        stroke([[-1 * dim/2, 0, 0], [dim/2, 0, 0]], 
            width=DIM_LINE_WIDTH, 
            endcaps="arrow2", 
            endcap_width=2, 
            endcap_length=2*3);
        tag("_dli_keep")
            attachable_text3d(label, size=font_size, h=h, anchor=CENTER)
                if (_defined(context))
                    attach(FWD, BACK)
                        attachable_text3d(context, size=font_size, h=h);
    }
}

/// Module: _dimension_line_outline()
/// Description:
///    ---> DIM <---
module _dimension_line_outline(dl, bounds, label, font_size, h, context=undef) {
    dim = dim_dim(dl);
    diff("_dlo_rem", "_dlo_keep") {
        tag("_dlo_rem")
            cube([dim, bounds.y, bounds.z], anchor=CENTER);
        stroke([[-1 * ((dim/2) + 4), 0, 0], [-1 * ((dim/2)), 0, 0]], 
            width=DIM_LINE_WIDTH, 
            endcap1="butt", 
            endcap2="arrow2", 
            endcap_width2=2, 
            endcap_length2=2*3);
        stroke([[ 1 * ((dim/2) + 4), 0, 0], [ 1 * ((dim/2)), 0, 0]], 
            width=DIM_LINE_WIDTH, 
            endcap1="butt", 
            endcap2="arrow2", 
            endcap_width2=2, 
            endcap_length2=2*3);
        tag("_dlo_keep")
            attachable_text3d(label, size=font_size, h=h, anchor=CENTER)
                if (_defined(context))
                    attach(FWD, BACK)
                        attachable_text3d(context, size=font_size, h=h);
    }
}

/// Module: _dimension_line_below_inline()
/// Description:
///    <---------->
///        DIM
module _dimension_line_below_inline(dl, bounds, label, font_size, h, context=undef) {
    dim = dim_dim(dl);
    stroke([[-1 * dim/2, 0, 0], [dim/2, 0, 0]], 
        width=DIM_LINE_WIDTH, 
        endcaps="arrow2", 
        endcap_width=2, 
        endcap_length=2*3);
    fwd(attachable_text3d_boundary(label, size=font_size, h=h).y)
        attachable_text3d(label, size=font_size, h=h, anchor=CENTER)
            if (_defined(context))
                attach(FWD, BACK)
                    attachable_text3d(context, size=font_size, h=h);
}

/// Module: _dimension_line_below_outline()
/// Description:
///    --->     <---
///         DIM
module _dimension_line_below_outline(dl, bounds, label, font_size, h, context=undef) {
    dim = dim_dim(dl);
    diff("_dlbo_rem", "_dlbo_keep") {
        tag("_dlbo_rem")
            cube([dim, DIM_LINE_WIDTH * 2, bounds.z], anchor=CENTER)
                tag("_dlbo_keep") {
                    attach(FWD, BACK)
                        attachable_text3d(label, size=font_size, h=h, anchor=CENTER)
                            if (_defined(context))
                                attach(FWD, BACK)
                                    attachable_text3d(context, size=font_size, h=h);
                }
        stroke([[-1 * ((dim/2) + 4), 0, 0], [-1 * ((dim/2)), 0, 0]], 
            width=DIM_LINE_WIDTH, 
            endcap1="butt", 
            endcap2="arrow2", 
            endcap_width2=2, 
            endcap_length2=2*3);
        stroke([[ 1 * ((dim/2) + 4), 0, 0], [ 1 * ((dim/2)), 0, 0]], 
            width=DIM_LINE_WIDTH, 
            endcap1="butt", 
            endcap2="arrow2", 
            endcap_width2=2, 
            endcap_length2=2*3);
    }
}


/// Module: dimension_line_extended()
/// Usage:
///   dimension_line_extended(dl);
///   dimension_line_extended(dl, <direction="back">, <anchor=CENTER>, <spin=0>, <orient=UP>);
///
/// Description:
///   Given a Dimension object `dl`, construct a dimension line with `dimension_line()` using the same
///   `dl` object, and then attach two extension lines to the dimension's endpoints that
///   extend along the `direction` direction axis, away from the measurement. Extension lines are
///   of the extension attribute `ext` length.
///   .
///   All handling of the dimension measurement displayed, the font size and thickness, the coloring
///   of the dimension lines, is all done per `dimension_line()`.
///
/// Arguments:
///   dl = A Dimension object
///   ---
///   direction = A string of one cardinal direction in which the dimension extension lines should extend. Must be one of `"back"`, `"fwd"`, `"up"`, or `"down"`. Default: `"back"`
///   anchor = Translate so anchor point is at origin `[0,0,0]`. Default: `CENTER`
///   spin = Rotate this many degrees around the Z axis after anchoring. Default: `0`
///   orient = Vector direction to which the model should point after spin. Default: `UP`
///
/// Continues:
///   The attachment bounding includes the extensions and the arrow-portion of dimension_line().
///   The bounding **does not** include any text from dimensional line.
///
/// Example:
///   dl = Dimension(["dim", 30, "ext", 20]);
///   dimension_line_extended(dl);
///
/// Todo:
///   man, this `direction` argument bugs me in the face of the object's `aso`; the value should be derived from `aso`
///
module dimension_line_extended(dl, direction="back", anchor=CENTER, spin=0, orient=undef) {
    log_fatal_unless(in_list(direction, ["back", "fwd", "up", "down"]),
        ["Unknown direction given", direction, ". Available directions are: back, fwd, up, & down"]);
    dimension = dim_dim(dl);
    extension = dim_ext(dl);
    log_warning_unless(_defined_and_nonzero(extension), 
        "No extension length specified. Check the 'ext' attribute of the given Dimension object");
    font_size = dim_font_size(dl);
    font_thickness = dim_font_thickness(dl);
    color = dim_color(dl);
    units = dim_units(dl);
    aso = dim_aso(dl);
    anch_ = aso[0];
    spin_ = _first_nonzero([ spin, aso[1] ]);
    orient_ = _first([ orient, aso[2] ]);

    ts = dimensional_text_and_bounding(dimension_text_formatting(dl), font_size, font_thickness);
    text = ts[0];
    text_b = ts[1];

    bounding_size = [
        sum([ dimension, (DIM_EXTL_WIDTH * 2) ]),
        sum([ extension, font_thickness ]),
        max([ text_b.z, (font_thickness * 2) ])
        ];
    anchors = [];

    attachable(anchor, spin_, orient_, size=bounding_size, anchors=anchors) {
        fwd(extension/2)
            color(color, alpha=DIM_COLOR_ALPHA)
                dimension_line(Dimension([ "aso", [anch_, 0, UP ]], mutate=dl)) {
                    attach(str("extension-left-", direction), BOTTOM)
                        cyl(d=DIM_EXTL_WIDTH, l=extension);
                    attach(str("extension-right-", direction), BOTTOM)
                        cyl(d=DIM_EXTL_WIDTH, l=extension);
                }
        children();
    }
}


/// Module: dimension_flyout()
/// Usage: as a module:
///   dimension_flyout(dl);
///
/// Description:
///   Given a Dimension object, contruct a flyout label for the dimension `dim` attribute using `flyout()` module.
///   Flyouts will be created pointing at wherever the object's position attribute `pos` is set. Flyout positioning,
///   angles all follow the rules within `flyout()`; flyout leg length is specfied by the extension attribute `ext`
///   value (if unset, `15` is used).
///   .
///   Dimension attributes `dim` will be reformatted according to the Dimension object, and combined into a single
///   text block with any specified context. Font sizing and thickness all derive from the object in the same way
///   `dimension_line()` does.
///   .
///   If the Dimension object has `isdiam` set, the flyout target will be a literal target, constructed by
///   `dimension_diam_target()`.
///
/// Arguments:
///   dl = A Dimension object
///
/// Example:
///   dl = Dimension(["dim", 30, "context", "A flyout point"]);
///   dimension_flyout(dl);
///
/// Example:
///   dl = Dimension(["dim", 30, "context", "A flyout point", "isdiam", true]);
///   dimension_flyout(dl);
///
/// Todo:
///   see if we can get an automatic adjustment of the flyout's leader lines, to shorten or lengthen the flyout relative to the model's size.
///   Instead of using `dimension_diam_target()`, we probably should look at something more flexible between it and `dimension_diam_circle()`.
///
module dimension_flyout(dl, anchor=CENTER, spin=0, orient=UP) {
    text = list_remove_values( full_flatten( [ [dimension_text_formatting(dl)], dim_context(dl) ] ), [undef], all=true);
    leader = dim_ext(dl, default=10);  // no default `ext` exists in the Dimension object
    font_size = dim_font_size(dl);
    font_thickness = dim_font_thickness(dl);
    color = dim_color(dl);

    flyout_path = [CENTER, apply(up(leader) * right(leader), CENTER)];
    size = [leader * 2, DIM_LINE_WIDTH * 4, leader * 2];
    anchors = [];

    attachable(anchor, spin, orient, size, anchors=anchors) {
        color(color, alpha=DIM_COLOR_ALPHA) {
            stroke(flyout_path, 
                width=DIM_LINE_WIDTH,
                endcap1="arrow2", 
                endcap_width1=DIM_LINE_WIDTH * 4, 
                endcap_length1=DIM_LINE_WIDTH * 12, 
                closed=false);

            move(flyout_path[1])
                attachable_text3d(text, h=font_thickness, size=font_size, anchor=LEFT, orient=FWD);

            if (dim_isdiam(dl) || dim_israd(dl))
                dimension_diam_target(dl);
        }
        children();
    }
}


/// Module: dimension_diam_target()
/// Usage:
///   dimension_diam_target(dl);
///   dimension_diam_target(dl, <anchor=CENTER>, <spin=0>, <orient=UP>);
///
/// Description:
///   Given a Dimension object, construct a target model suitable for placement
///   over top a bored section of a model, such as an axle bore.
///   The target's diameter is pulled from the object's dimension attribute `dim`,
///   and its thickness and sizing come from the font thickness attribute `font_thickness`,
///   and its color comes from the attribute `color`.
///
/// Arguments:
///   dl = A Dimension object
///   ---
///   anchor = Translate so anchor point is at origin `[0,0,0]`. Default: `CENTER`
///   spin = Rotate this many degrees around the Z axis after anchoring. Default: `0`
///   orient = Vector direction to which the model should point after spin. Default: `UP`
///
/// Continues:
///   It is not an error to specify a Dimension object that does not have its `isdiam`
///   or `israd` attributes set to `true`, but perhaps it should be.
///
/// Example:
///   dl = Dimension(["dim", 20, "isdiam", true]);
///   dimension_diam_target(dl);
///
module dimension_diam_target(dl, anchor=CENTER, spin=0, orient=UP) {
    // build a target based on DL attributes
    font_thickness = dim_font_thickness(dl);
    color = dim_color(dl);
    diam = dim_dim(dl);
    attachable(anchor, spin, orient, r=(diam + font_thickness)/2, h=font_thickness/2) {
        color(color, alpha=DIM_COLOR_ALPHA)
            tube(od=diam, id=diam - font_thickness, h=font_thickness/2, anchor=CENTER)
                attach(CENTER)
                    zrot_copies([0, 90])
                        cyl(d=font_thickness/2, l=diam, orient=RIGHT);
        children();
    }
}


/// Module: dimension_diam_circle()
/// Usage:
///   dimension_diam_circle(dl);
///   dimension_diam_circle(dl, <anchor=CENTER>, <spin=0>, <orient=UP>);
///
/// Description:
///   Given a Dimension object, construct a circle model suitable for placement
///   over top a bored section of a model, such as an axle bore, that indicates the
///   dimension.
///   The circle's diameter is pulled from the object's dimension attribute `dim`,
///   and its thickness and sizing come from the font thickness attribute `font_thickness`,
///   and its color comes from the attribute `color`.
///
/// Arguments:
///   dl = A Dimension object
///   ---
///   anchor = Translate so anchor point is at origin `[0,0,0]`. Default: `CENTER`
///   spin = Rotate this many degrees around the Z axis after anchoring. Default: `0`
///   orient = Vector direction to which the model should point after spin. Default: `UP`
///
/// Continues:
///   It is not an error to specify a Dimension object that does not have its `isdiam`
///   or `israd` attributes set to `true`, but perhaps it should be.
///   .
///   This current iteration of `dimension_diam_circle()` is incomplete: it doesn't correctly place
///   text elements within the diameter as we need it to, nor does it place the text
///   *outside* the circle when the diameter is too small.
///
/// Example:
///   dl = Dimension(["dim", 20, "isdiam", true]);
///   dimension_diam_circle(dl);
///
/// Todo:
///   figure this out. This module isn't really in use, but probably should be.
///   if we keep this, correct how text is meant to be placed when the diameter is too small
///
module dimension_diam_circle(dl, anchor=CENTER, spin=0, orient=UP) {
    diam = dim_dim(dl);
    font_thickness = dim_font_thickness(dl);
    color = dim_color(dl);

    dt = dimensional_text_and_bounding(
        dimension_text_formatting(dl),
        dim_font_size(dl),
        font_thickness);
    dt_text = dt[0];
    dt_text_bounding = dt[1];

    // determine the placement of text and arrows in relation to the
    // dimension diameter of the circle we're about to draw:
    text_fits_inside = (dt_text_bounding.x * 1.2 < diam && dt_text_bounding.y * 1.1 < diam);
    arrows_fit_inside = ((font_thickness * 2) + 1) < diam;


    // TODO - diam is.. not right; it might be diam * 2
    attachable(anchor, spin, orient, r=diam/2, h=font_thickness) {
        color(color, alpha=DIM_COLOR_ALPHA)
            diff("rem-dim-cir", "keep-dim-cer")
                tube(od=diam, id=diam - font_thickness, h=font_thickness/2, anchor=CENTER) {
                    if (arrows_fit_inside) {
                        attach(CENTER)
                            dimension_line(obj_accessor_unset(dl, "context"));
                    } else if (text_fits_inside) {
                        // needs a diff masking block, here
                        attach(CENTER, CENTER)
                            tag("rem-dim-cir")
                                cube(dt_text_bounding, anchor=CENTER);
                        attach(CENTER, CENTER)
                            tag("keep-dim-cer")
                                attachable_text3d(dt_text, size=dim_font_size(dl), h=font_thickness, pad=1);
                    } else {
                        attach(RIGHT, LEFT, overlap=(arrows_fit_inside) ? 0 : neg(2)) // `2` should be the length of the outer axle
                            attachable_text3d(dt_text, size=dim_font_size(dl), h=font_thickness, pad=1);
                    }
                }
        children();
    }
}


/// Function: dimensional_text_and_bounding()
/// Usage:
///   [text, bounding] = dimensional_text_and_bounding(text_string, size, h);
///   [text, bounding] = dimensional_text_and_bounding(text_string, size, h, <pad=0.5>);
/// Description:
///   Given a string of text `text_string`, a size at which you want to model that text `size`, and
///   a height (or thickness) `h`, returns a list containing both a (potentially) modified text string,
///   and a list of boundary sizes of the form `[x, y, z]` lengths. Both of these are returned in a
///   single list: `[text, bounding]`. The `text` returned may differ from the given `text_string`, but
///   not by much; the only difference should be in the case where the `text_string` is an integer;
///   in which case the returned `text` will be that integer, but cast as a string.
/// Arguments:
///   text_string = A string of text with which to get bounding. No default
///   size = The size to measure the text at. No default
///   h = The height (thickness) of the text to measure at. No default
///   ---
///   pad = Additional text padding around which to take account when producing boundary measurements. Default: `0.5`
/// Todo:
///   returned `text` really isn't going to differ too much from provided `text_str`: determine if we really need to return this at all, and if not then don't.
///
function dimensional_text_and_bounding(text_str, size, h, pad=0.5) = let(
    text_str_ = (is_int(text_str)) ? str(text_str) : text_str,
    text_bounding_ = attachable_text3d_boundary(text_str_, size=size, h=h, pad=pad)
    )
    [text_str_, text_bounding_];


/// Function: dimension_text_formatting()
/// Usage:
///   text_string = dimension_text_formatting(dl);
/// Description:
///   Given a Dimension object, return a string for the dimension `dim` attribute arranged as
///   directed within the object, as it should be displayed.
/// Arguments:
///   dl = A Dimension object. No default
/// Continues:
///   None of these attribute-based decorations are exclusive among each other, though perhaps some should be
///   (eg, there aren't any cases where a single dimension `dim` attribute measurement would have *both*
///   `isdiam` and `israd` set to `true`).
/// Example: no changes formatting
///   dl = Dimension(["dim", 30]);
///   v = dimension_text_formatting(dl);
///   // v == "30"
///
/// Example: as a diameter
///   dl = Dimension(["dim", 30, "isdiam", true]);
///   v = dimension_text_formatting(dl);
///   // v == "Ø30";
///
/// Example: as a radius
///   dl = Dimension(["dim", 30, "israd", true]);
///   v = dimension_text_formatting(dl);
///   // v == "R30";
///
/// Example: as a measurement in degrees
///   dl = Dimension(["dim", 30, "isdeg", true]);
///   v = dimension_text_formatting(dl);
///   // v == "30°"
///
/// Example: with units specified
///   dl = Dimension(["dim", 30, "units", "mm"]);
///   v = dimension_text_formatting(dl);
///   // v == "30mm"
///
/// Example: with a tolerance specified
///   dl = Dimension(["dim", 30, "units", "mm", "tolerance", 0.2]);
///   v = dimension_text_formatting(dl);
///   // v == "30mm (±0.2)"
///
function dimension_text_formatting(dl) =
    let(
        dimension = dim_dim(dl),
        t_ = str(
            (dim_isdiam(dl))             ? "Ø" : "",
            (dim_israd(dl))              ? "R" : "",
            dimension,
            (dim_isdeg(dl))              ? "°" : "",
            (_defined(dim_units(dl)))     ? dim_units(dl) : "",
            (_defined(dim_tolerance(dl))) ? str(" (±", dim_tolerance(dl), ")") : ""
        )
    ) t_;


/// Function: convert_parent_geom_to_dimensions()
/// Usage:
///   dimlist = convert_parent_geom_to_dimensions();
///   dimlist = convert_parent_geom_to_dimensions(geom);
/// Description:
///    Given a geometry that was constructed with BOSL2's `attach_geom()`,
///    return a list of Dimension objects `list` that describe that geometry. The list 
///    can be of any length, and Dimension objects may appear in any order. 
///    .
///    Known geometry types as of 2022/12 are: `prismoid`, `conoid`, `vnf_extents`, `sphereoid`. 
///    Most `sphereoid` and `conoid` objects are supported; shapes that are partially constructed 
///    like pie-wedge, or that have non-standard features like onion or teardrop, only have 
///    partial dimension support. `vnf-extent` shapes only have basic dimensioning surrounding 
///    their outer-bounding box on three axes. Nearly all `prismoid` shapes are supported, with the 
///    exception to wedge, which has a minor placement problem.
/// Arguments:
///   geom = A BOSL2-generated geometry for a single model (eg, `$parent_geom`). No default.
/// Continues:
///   It is an error to call this function in the absence of a valid geometry, either one that 
///   has already been interpreted and passed via the `geom` argument, or one that is 
///   gleanable from `$parent_geom` as set by `attach_geom()`.
/// Todo:
///   Revisit & potentially overhaul the conversion of `$parent_geom` to Dimension placement once BOSL2 is officially "done". 
///
function convert_parent_geom_to_dimensions(geom=undef) =
    let(
        geom_ = (_defined(geom) && obj_is_obj(geom)) 
            ? geom 
            : Geom() 
    )
    assert(geom_)
    let(
        type = geom_type(geom_),
        boundary = parent_geom_bounding_box(geom_)
    )
    (type == "prismoid")
        ? list_remove_values(_dimension_geom_prismoid(geom_), undef, all=true)
        : (type == "conoid")
            ? list_remove_values(_dimension_geom_conoid(geom_), undef, all=true)
            : (type == "spheroid")
                ? [
                    Dimension([
                        "dim", geom_radius1(geom_) * 2,
                        "isdiam", true,
                        "aso", [CENTER+FWD, 0, UP],
                        "context", "diameter"
                        ])
                    ]
                : (_defined(geom_vnf(geom_)))
                    ? let( _ = log_info(
                            ["converting VNF to dimensions isn't yet fully supported; returning basic XYZ boundary as Dimension entries: ", 
                            boundary]) 
                            )
                        [
                            Dimension([ "dim", boundary.x, "aso", [CENTER+FWD, 0, UP], ]),
                            Dimension([ "dim", boundary.y, "aso", [CENTER+RIGHT, 90, UP], ]),
                            Dimension([ "dim", boundary.z, "aso", [CENTER+LEFT, 270, FWD], ]),
                        ]
                    : log_fatal(["convert_parent_geom_to_dimensions(): Unknown attach_geom type", type ]);


function _dimension_geom_prismoid(geom) =
    assert(obj_is_obj(geom) && obj_toc_get_type(geom) == "Geom")
    assert(geom_type(geom) == "prismoid")
    let(
        s1 = geom_size(geom),
        s2_ = geom_size2(geom),
        s2 = (s1.x != s2_.x || s1.y != s2_.y)
            ? s2_
            : undef,
        axis = geom_axis(geom)
    )
    [
        // s1.x
        Dimension(["dim", s1.x,
            "aso", (axis == UP || axis == DOWN)
                ? [ BOTTOM+FWD, 0, UP ]
                : (axis == LEFT || axis == RIGHT)
                    ? [ FWD+LEFT, 0, RIGHT]  // BRAK
                    : (axis == FWD || axis == BACK)
                        ? [ BOTTOM+FWD, 0, UP ]
                        : log_warning_assign(undef, ["unknown axis", axis, ", assigning to aso"]),
            "context", "s1.x",
            ]),

        // s2.x
        (_defined(s2))
            ? Dimension(["dim", s2.x,
                "aso", (axis == UP || axis == DOWN)
                    ? [ TOP+FWD, 0, UP ]
                    : (axis == LEFT || axis == RIGHT)
                        ? [ FWD+RIGHT, 0, RIGHT]  // BRAK
                        : (axis == FWD || axis == BACK)
                            ? [ TOP+FWD, 0, UP ]
                            : log_warning_assign(undef, ["unknown axis", axis, ", assigning to aso"]),
                "context", "s2.x",
                ])
            : undef,

        // s1.y
        Dimension(["dim", s1.y,
            "aso", (axis == UP || axis == DOWN)
                ? [ RIGHT+BOTTOM, 90, UP ]
                : (axis == LEFT || axis == RIGHT)
                    ? [ TOP+LEFT, 0, RIGHT ]
                    : (axis == FWD || axis == BACK)
                        ? [ FWD+RIGHT, 270, FWD ]
                        : log_warning_assign(undef, ["unknown axis", axis, ", assigning to aso"]),
            "context", "s1.y"
            ]),

        // s2.y
        (_defined(s2))
            ? Dimension(["dim", s2.y,
                "aso", (axis == UP || axis == DOWN)
                    ? [ RIGHT+TOP, 90, UP ]
                    : (axis == LEFT || axis == RIGHT)
                        ? [ TOP+RIGHT, 0, RIGHT ]  // RBAK
                        : (axis == FWD || axis == BACK)
                            ? [ FWD+RIGHT, 270, FWD ] // BRAK
                            : log_warning_assign(undef, ["unknown axis", axis, ", assigning to aso"]),
                "context", "s2.y"
                ])
            : undef,


        // s1.z
        Dimension(["dim", s1.z,
            "aso", (axis == UP || axis == DOWN)
                ? [ LEFT+CENTER, 270, FWD ]
                : (axis == LEFT || axis == RIGHT)
                    ? [ FWD+BOTTOM, 0, UP ]
                    : (axis == FWD || axis == BACK)
                        ? [ RIGHT+BOTTOM, 270, UP ]
                        : log_warning_assign(undef, ["unknown axis", axis, ", assigning to aso"]),
            "context", "s1.z"
            ]),
    ];


function _dimension_geom_conoid(geom) =
    assert(obj_is_obj(geom) && obj_toc_get_type(geom) == "Geom")
    assert(geom_type(geom) == "conoid")
    let(
        r1 = geom_radius1(geom),
        r2_ = geom_radius2(geom),
        r2 = (r1 != r2_) 
            ? r2_ 
            : undef,
        h = geom_length(geom),
        axis = geom_axis(geom)
    )
    [
        // r1
        Dimension(["dim", r1 * 2,
            "isdiam", true,
            "aso", (axis == UP || axis == DOWN)
                ? [BOTTOM+FWD, 0, UP]
                : (axis == LEFT || axis == RIGHT)
                    ? [FWD+LEFT, 0, RIGHT]  // BRAK
                    : (axis == FWD || axis == BACK)
                        ? [CENTER+FWD, 0, UP]
                        : log_warning_assign(undef, ["unknown axis", axis, ", assigning to aso"]),
            "context", "r1",
            ]),

        // r2
        (_defined(r2))
            ? Dimension(["dim", r2 * 2,
                "isdiam", true,
                "aso", (axis == UP || axis == DOWN)
                    ? [TOP+FWD, 0, UP]
                    : (axis == LEFT || axis == RIGHT)
                        ? [FWD+RIGHT, 0, RIGHT]  // BRAK
                        : (axis == FWD || axis == BACK)
                            ? [CENTER+BACK, 180, UP]
                            : log_warning_assign(undef, ["unknown axis", axis, ", assigning to aso"]),
                "context", "r2",
                ])
            : undef,

        // height
        Dimension(["dim", h,
            "aso", (axis == UP || axis == DOWN)
                ? [CENTER+LEFT, 270, FWD]
                : (axis == LEFT || axis == RIGHT)
                    ? [CENTER+TOP, 180, FWD]
                    : (axis == FWD || axis == BACK)
                        ? [LEFT+CENTER, 270, UP]
                        : log_warning_assign(undef, ["unknown axis", axis, ", assigning to aso"]),
            "context", "height (z)",
            ]),
    ];


/// ---------------------------------------------------------------------------------------
/// Section: Dimension Object Functions
///   These functions leverage the OpenSCAD Object library to create a Dimension Object and its attribute accessors.
///   See https://github.com/jon-gilbert/openscad_objects/blob/main/docs/HOWTO.md for a quick primer on constructing and
///   using Objects; and https://github.com/jon-gilbert/openscad_objects/blob/main/docs/object_common_functions.scad.md for
///   details on Object functions.
///
/// Subsection: Construction
///
/// Function: Dimension()
/// Description:
///   Given either a variable list of attributes and values, or an existing object from
///   from which to mutate, constructs a new `dim` object list and return it.
///   .
///   `Dimension()` returns a list containing an opaque object. See `Object()` in https://github.com/jon-gilbert/openscad_objects/blob/main/docs/object_common_functions.scad.md#function-object.
/// Usage:
///   obj = Dimension();
///   obj = Dimension(vlist);
///   obj = Dimension(vlist, mutate=obj);
/// Arguments:
///   ---
///   vlist = Variable list of attributes and values, eg: `[["length", 10], ["style", undef]]`. Default: `[]`.
///   mutate = An existing `dim` object on which to pre-set object values. Default: `[]`.
/// Example:
///   dim = Dimension();
function Dimension(vlist=[], mutate=[]) = Object("Dimension", Dimension_attrs, vlist=vlist, mutate=mutate);

/// Constant: Dimension_attributes
/// Description:
///   A list of all `dim` attributes.
/// Attributes:
///   dim = i = The dimension value for this Dimension object. No default.
///   context = s = Additional context to present underneath or alongside the dimension value. No default.
///   tolerance = i = A value of tolerance for the specified dimension. No default.
///   units = s = A string to be used as the dimension units, if specified (eg, `"mm"`, `"ft"`). No default.
///   isdiam = b = If set to `true`, the dimension will be considered a diameter, and have its labels and placements adjusted accordingly. Default: `false`
///   israd = b = If set to `true`, the dimension will be considered a radius, and have its labels and placements adjusted. Default: `false`
///   isdeg = b = If set to `true`, the dimension will be considered an angle in degrees, and have its label adjusted. Default: `false`
///   ext = i = The length of the extension lines (and, the distance from the centerline of the model this dimension should be presented). No default.
///   aso = l = A list tuple of three settings: the position anchor the Dimension should attach to (*on the parent*); a number of degrees to spin the Dimension model before positioning it onto the parent; and, the orientation to use for the Dimension model before positioning or spinning. Default: `[FWD+BOTTOM, 0, UP]`
///   font_size = i = Size of the font the dimension and context will be presented in. Default: `2`
///   font_thickness = i = The thickness (or height) the font will be produced at. Default: `0.5`
///   color = s = Name of color to render dimensions, their lines & extensions, and context in. Default: `black`
/// Todo:
///   perhaps `units` should be default-set to "mm"? We seem to use it that way almost universally. 
Dimension_attrs = [
    // attributes about the dimension itself:
    "dim=i",
    "context=s",
    "tolerance=i",
    "units=s",
    "isdiam=b=false",
    "israd=b=false",
    "isdeg=b=false",
    "isflyout=b=false",
    "ext=i",
    // anchor-spin-orient: how to position against
    // the dimension's parent, degrees of spin to apply after
    // modeling but before positioning, and direction to
    // face the dimension when creating
    ["aso", "l", [ FWD+BOTTOM, 0, UP ]],
    ["aso_post_translate", "l", [0,0,0]],
    "font_size=i=2",
    "font_thickness=i=0.5",
    "color=s=black",
    [ "pos", "l", [] ],  // TODO: dimension_flyout references this attribute. We don't want to use it. Remove in favor of `aso` positioning.
    ];


/// Subsection: Attribute Accessors
///   Each of the attributes listed in `Dimension_attributes` has an accessor built for it, a function
///   for getting and setting the attribute's value within the Dimension object.
///   Each of the attributes listed above has an accessor with the syntax as `dim_dim()`, below.
///
/// Function: dim_dim()
/// Usage:
///   value = dim_dim(dim, <default=undef>);
///   new_dim = dim_dim(dim, nv=new_value);
/// Description:
///   Mutatable object accessor for the `dim` attribute. Given an `dim` object, operate on that object. The operation
///   depends on what other options are passed.
///   .
///   Calls to `dim_dim()` with no additional options will look up the
///   value of `dim` within the object and return it. If a `default` option is provided to `dim_dim()` and
///   `dim` is unset, the value of `default` will be returned instead.
///   .
///   Calls to `dim_dim()` with a `nv` (new-value) option will return a wholly new Dimension object, whose
///   `dim` attribute is set to the value of `nv`. *The existing Dimension object is unmodified.*
/// Arguments:
///   dim = A Dimension Object. No default.
///   ---
///   default = If provided, and if there is no value currently set for `dim`, `dim_dim()` will instead return this provided value. No default.
///   nv = If provided, `dim_dim()` will return a new Dimension object with the new value set for `whatever`. The existing `dim` object is unmodified. No default.
/// Continues:
///   It is not an error to call `dim_dim()` with both `default` and `nv`, however if they are both defined only the `nv` "set"
///   operation is performed. Note that setting `nv` to `undef` expecting to clear the value of `dim` won't produce a new object;
///   to clear the value of `dim`, you must use `obj_accessor_unset()`.
/// Example:
///   dim = Dimension();
///   val = dim_dim(dim);
/// Example:
///   dim = Dimension();
///   new_dim = dim_dim(dim, nv="new");
///
function dim_dim(dl, default=undef, nv=undef) = obj_accessor(dl, "dim", default=default, nv=nv);
function dim_context(dl, default=undef, nv=undef) = obj_accessor(dl, "context", default=default, nv=nv);
function dim_tolerance(dl, default=undef, nv=undef) = obj_accessor(dl, "tolerance", default=default, nv=nv);
function dim_units(dl, default=undef, nv=undef) = obj_accessor(dl, "units", default=default, nv=nv);
function dim_isdiam(dl, default=undef, nv=undef) = obj_accessor(dl, "isdiam", default=default, nv=nv);
function dim_israd(dl, default=undef, nv=undef) = obj_accessor(dl, "israd", default=default, nv=nv);
function dim_isdeg(dl, default=undef, nv=undef) = obj_accessor(dl, "isdeg", default=default, nv=nv);
function dim_isflyout(dl, default=undef, nv=undef) = obj_accessor(dl, "isflyout", default=default, nv=nv);
function dim_ext(dl, default=undef, nv=undef) = obj_accessor(dl, "ext", default=default, nv=nv);
function dim_aso(dl, default=undef, nv=undef) = 
    let(
        dl_ = (_defined(nv))
            ? obj_accessor(dl, "aso", default=default, nv=nv)
            : dl,
        existing_aso = obj_accessor_get(dl_, "aso", default=default),
        returnable_aso = [
            _first([ existing_aso[0], "FWD+BOTTOM" ]),
            _first([ existing_aso[1], 0 ]),
            _first([ existing_aso[2], UP ])
            ]
    )
    (nv) ? dl_ : returnable_aso;
function dim_aso_post_translate(dl, default=undef, nv=undef) = obj_accessor(dl, "aso_post_translate", default=default, nv=nv);
function dim_font_size(dl, default=undef, nv=undef) = obj_accessor(dl, "font_size", default=default, nv=nv);
function dim_font_thickness(dl, default=undef, nv=undef) = obj_accessor(dl, "font_thickness", default=default, nv=nv);
function dim_color(dl, default=undef, nv=undef) = obj_accessor(dl, "color", default=default, nv=nv);
function dim_pos(dl, default=undef, nv=undef) = obj_accessor(dl, "pos", default=default, nv=nv);


/// Section: Constants
///
/// Constant: DIM_COLOR_ALPHA
/// Description:
///   Alpha-channel level for dimension coloring. Currently: `0.5`
DIM_COLOR_ALPHA = 0.5;

DIM_LINE_WIDTH = 0.5; 

DIM_EXTL_WIDTH = 0.25;


/// Function: _first_nonzero()
/// Synopsis: Carryover from 507common's `first_nonzero()`
/// Description:
///   Given a list of numerical elements, return the first defined, non-zero element in the list.
///   NB: non-zero really does mean non-zero; a list of `[0, -1, 1]` will yield `-1`.
function _first_nonzero(list) = [for (i = list) if (is_num(i) && i != 0) i][0];


