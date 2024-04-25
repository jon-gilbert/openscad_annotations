// LibFile: annotate.scad
//   Functions and modules for annotating OpenSCAD models
//   Annotations are in-scene flyout blocks of information on specific models.
//
// FileSummary: Functions and modules for annotating models
// Includes:
//   include <openscad_annotations/annotate.scad>
//   MECH_NUMBER = "EX";
//

include <openscad_annotations/common.scad>
include <openscad_annotations/flyout.scad>

/// Section: Constants
///
/// Constant: MECH_NUMBER
/// Description:
///   The global `MECH_NUMBER` identifies the model-id of the mechanism in a given .scad file. You **should** set this constant within your 
///   model file somewhere for part-numbers to work well. You may only set `MECH_NUMBER` once.
///   .
///   Throughout the annotation.scad documentation below, and in the examples, we use `EX` as a `MECH_NUMBER` 
///   (to indicate that it is an "example"). 
///   .
///   Currently: `false`, so as to indicate not-set.
MECH_NUMBER = false;

/// Constant: EXPAND_PARTS
/// Description: 
///   Boolean variable that can instruct models using `partno()` to 
///   "part-out" their models, by expanding deliniated parts away 
///   from their modeled position. 
///   Currently: `false`
/// See Also: partno()
EXPAND_PARTS = false;


/// Section: Scope-level Constants
/// 
/// Constant: $_anno_labelname
/// Description: 
///   Holds the `label` annotation string within the model.
$_anno_labelname = undef;
/// Constant: $_anno_partno
/// Description: 
///   Holds the `partno` annotation list within the model.
$_anno_partno = [];
/// Constant: $_anno_desc
/// Description: 
///   Holds the `desc` annotation string within the model.
$_anno_desc = undef;
/// Constant: $_anno_spec
/// Description: 
///   Holds the `spec` annotation list-of-lists within the model.
$_anno_spec = undef;
/// Constant: $_anno_obj
/// Description: 
///   Holds the `obj` annotation object within the model.
$_anno_obj = undef;
/// Constant: $_anno_obj_measure
/// Description: 
///   Holds the `obj-measure` annotation list-of-lists within the model.
$_anno_obj_measure = [[],[]];



// Section: Modules that Apply Annotations to Models
//   Labeling and describing shapes and models with Annotations happens in two steps. The first step applies the annotation, 
//   be it a simple label ("tab-A"), a descriptive block of text ("fits into slot B"), a part-number ("A-001-X"), or 
//   whatever; the second step produces the in-scene textual elements applied to the shape, the actual act of annotation.
//   .
//   The modules in this section do the first step: they apply the notes and annotation to child shapes and models, to be 
//   rendered into an annotation in the next step.
//
// Module: label()
// Synopsis: Apply a label annotation to a hierarchy of children modules
// Usage:
//   label(name) [CHILDREN];
// Description:
//   Applies `name` as a label. A label is a simple, discrete name useful in directions or 
//   explanations, such as "tab A" or "slot B". When annotated, labels have the largest and 
//   most prominent display.
//   .
//   Label assignment is hierarchical, in that all children beneath the `label()` call will 
//   have the same label. Label assignment is singular, in that there is only ever 
//   one label assigned to a 3D element when annotated. 
// 
// Arguments:
//   name = A string to set as the label for all child elements. 
//
// Continues: 
//   Calling `label()` with no `name` argument clears the presence of a label annotation 
//   for subsequent children.
//
// Example: assigning a label: the cuboid is assigned label "A", and when annotated, that label appears:
//   label("A")
//     cuboid(10)
//       annotate(show=["label"]);
//
// Example: labels apply to all models within the child hierarchy: the cuboid is assigned label "A" and that shows when annotated as in Example 1; the child sphere inherits that same label, and shows that when annotated:
//   label("A")
//     cuboid(10) {
//       annotate(show=["label"]);
//       up(10)
//         sphere(6)
//           annotate(show=["label"]);
//     }
//
// Example: Changing labels in the hirearchy: the cuboid is assigned label "A", and later in the hirearchy the sphere is assigned an `undef` label, clearing its assignment of "A". The child to that sphere, the smaller cuboid, is assigned label "B". All three elements show the correct label (or lack of label) when annotated:
//   label("A")
//     cuboid(10) {
//       annotate(show=["label"]);
//       up(10)
//         label(undef)
//         sphere(6) {
//           annotate(show=["label"]);
//           label("B")
//             back(12) 
//               cuboid(6)
//                 annotate(show=["label"]);
//         }
//     }
//
module label(name) {
    $_anno_labelname = name;
    children();
}

// Module: desc()
// Synopsis: Apply a description annotation to a hierarchy of children modules
// Usage:
//   desc(name) [CHILDREN];
// Description:
//   Applies `name` as a description. A description is additional context, a few short words.
//   .
//   Descriptions are hierarchical, in that all children beneath the `desc()` call will 
//   have the same description. Description assignment is singular, in that there is only ever 
//   one description assigned to a model when annotated. 
//   .
//   This is a convienence module for setting the description without calling `annotate()`, 
//   and should be used sparingly. 
//   Ideally, descriptions are specified at annotation time, to provide additional 
//   context to the model part, alongside the label, part-number, specification, and object
//   details. Using `desc()` allows context to be created within models without forcing 
//   an `annotate()` call in the model. 
// 
// Arguments:
//   name = A string to set as the desc for all child elements. 
//
// Continues: 
//   Calling `desc()` with no `name` argument clears the presence of a label annotation 
//   for subsequent children.
//
// Example: assigning a description:
//   desc("A very special cuboid")
//     cuboid(10)
//       annotate(show=["desc"]);
//
// Example: a description applies to all models within the child hierarchy: a description is assigned above the cuboid, and it is present for all elements below that hirearchy:
//   desc("Special cube")
//     cuboid(10) {
//       annotate(show=["desc"]);
//       up(10)
//         sphere(6)
//           annotate(show=["desc"]);
//     }
//
// Example: Precedence is given to `annotate()` for descriptions: when `desc()` is used in the same hirearchy as an `annotate()` call with a description, the description provided to `annotate()` will be shown:
//   desc("A good cuboid")
//     cuboid(10) 
//       annotate("Not such a great cube, actually", show=["desc"]);
//
module desc(name) {
    $_anno_desc = name;
    children();
}

// Module: partno()
// Synopsis: Apply a part-number annotation to a hierarchy of children modules
// Usage:
//   partno(val) [CHILDREN];
// Description:
//   Appends `val` to existing part-numbers. A part-number is an identifier for discrete sub-sections of 
//   a model.
//   .
//   Appends `val` to existing part-numbers to all children hirearchically beneath the `partno()` call. 
//   Part-numbers are hirearchical and cumulatively collected, implying a chain of parentage. 
//   Calling `partno()` multiple times in a child hirearchy will add each call's `val` to the part-number 
//   element list. 
//   When annotated, the elements in the list of part-numbers are collected with a hyphen (`-`) at the 
//   specified level.
//   .
//   A fully-collected part-number has the following format: 
//   ```
//   partno = mech-number, sep, [ label, sep ], part-number, sep, { part-number, sep } ;
//   sep = "-" ;
//   chars = a .. z, A .. Z, 0 .. 9, _ ;
//   mech-number = { chars } ;
//   label = { chars } ;
//   part-number = { chars } ;
//   ```
//   Examples: `EX-1`, `EX-B-1`, `EX-B-1-02-2a`
//   .
//   Part-numbers are predicated on the existance of `MECH_NUMBER`, that uniquely identifies the entire
//   mechanism being modeled (eg, `002`). *(OpenSCAD doesn't offer the facility to query the filename 
//   being operated on for reasons beyond knowing, and this variable must be set somehow.)* Ideally 
//   the `MECH_NUMBER` value is set in your model just after where `openscad_annotations/annotate.scad` is included.)*
//   .
//
// Arguments:
//   val = A string to append to the current part numbers. 
//   start_new = A boolean which, if set to `true`, clears previous part numbers from the hirearchy before applying `val`. Default: `false`
//
// Continues:
//   **Parting out:** Part-numbers have a second use, in addition to providing annotation markings for models: `partno()` 
//   provides a deliniation of parts within the model. Parts within the model that are delineated 
//   can be automatically expanded, parted-out, for examination or construction. This is especially 
//   useful for visualizing the internal aspects of models with that have moving parts not easily seen.
//   .
//   Part expansion applies to the entire scene, by setting `EXPAND_PARTS` within the .scad file to `true`.
//   When `EXPAND_PARTS` is set to `true`, calls to `partno()` will translate its children to a 
//   new position in the scene. The position is derived *from* the part-number, and should reasonably
//   relocate deliniated parts via `move()` so that inspection or construction is eased. 
//   
//
// Example: simple `partno()` use: the cube is part number `1`, and is annotated to show that:
//   partno(1)
//     cuboid(30)
//       annotate(show=["partno"]);
//
// Example: hirearchical part-number use: children inherit the part-number of their ancestors; this single child tree yields parts `EX-30`, `EX-30-16`, and `EX-30-16-5`
//   partno(30)
//     cuboid(30) {
//       annotate(show=["partno"]);
//         attach(TOP, BOTTOM)
//           partno(16)
//             cuboid(16) {
//               annotate(show=["partno"]);
//                 attach(TOP, BOTTOM)
//                   partno(5)
//                     cuboid(5)
//                       annotate(show=["partno"]);
//           }
//      }
//
// Example: setting, then clearing, a part-number, to start a new part-number inheritance; the cube at part-number `5` has its inheritance reset, yielding parts `EX-30`, `EX-30-16`, and `EX-5`, even though they are all within the same child tree
//   partno(30)
//     cuboid(30) {
//       annotate(show=["partno"]);
//         attach(TOP, BOTTOM)
//           partno(16)
//             cuboid(16) {
//               annotate(show=["partno"]);
//                 attach(TOP, BOTTOM)
//                   partno(5, start_new=true)
//                     cuboid(5)
//                       annotate(show=["partno"]);
//           }
//      }
//   
// Example: part-number values can be strings:
//   partno("r2")
//     cuboid(30)
//       annotate(show=["partno"]);
//
// Example: if present, part-numbers incorporate labels when annotated:
//   label("A")
//     partno(1)
//       cuboid(30)
//         annotate(show=["partno"]);
//
// Example: if you're working with a BOSL2 distributor that sets `$idx` as a side-effect, naturally you can leverage that within `partno()`:
//   partno(1)
//     zrot_copies(n=5, r=20, subrot=false)
//       partno($idx)
//         sphere(r=3)
//           annotate(show=["partno"], anchor=TOP, leader_len=3);
//
// Example: un-parted sphere-within-sphere: a sphere (`EX-1-2`) exists within another, hollow sphere (`EX-1`), but isn't visible by design:
//   partno(1)
//      diff()
//        sphere(d=20) {
//          attach(CENTER)
//            tag("remove")
//              sphere(d=19);
//          
//          annotate(show="ALL");
//          
//          attach(CENTER)
//            tag("keep")
//              partno(2)
//                sphere(d=10)
//                  annotate(show="ALL");
//        }
//
// Example: parted-out sphere-within-sphere: same example as above, a sphere-within-a-sphere, but expanded: `EX-1-2` and `EX-1` are relocated via `partno()`, and both parts of the model are shown:
//   EXPAND_PARTS = true;
//   partno(1)
//      diff()
//        sphere(d=20) {
//          attach(CENTER)
//            tag("remove")
//              sphere(d=19);
//           
//          annotate(show="ALL");
//           
//          attach(CENTER)
//            tag("keep")
//              partno(2)
//                sphere(d=10)
//                  annotate(show="ALL");
//        }
//
module partno(partno, start_new=false) {
    $_anno_partno = (start_new)
        ? [ partno ]
        : (_defined($_anno_partno)) 
            ? concat($_anno_partno, partno) 
            : [ partno ];

    trans_vector = (EXPAND_PARTS) ? partno2translate() : [0,0,0];

    move(trans_vector)
        children();
}


// Module: partno_attach()
// Synopsis: attachable-aware partno() module 
// Usage:
//   [ATTACHABLE] partno_attach() [CHILDREN];
// Description:
//   Combines the functionality of BOSL2's `attach()` and `partno()`. 
//   .
//   You'll need to review the documentation for `attach()`.
//
// Arguments:
//   from = The vector, or name of the parent anchor point to attach to.
//   to = Optional name of the child anchor point.  If given, orients the child such that the named anchors align together rotationally.
//   ---
//   overlap = Amount to sink child into the parent.  Equivalent to `down(X)` after the attach.  This defaults to the value in `$overlap`, which is `0` by default.
//   partno = A string to append to the current part numbers. When `partno` is unspecified, `partno_attach()` behaves the same as `attach()`. If `partno` is set to the literal value `"idx"`, the attach value `$idx` will be used. Default: `undef` 
//   norot = If true, don't rotate children when attaching to the anchor point.  Only translate to the anchor point. Default: `false`
//   start_new = A boolean which, if set to `true`, clears previous part numbers from the hirearchy before applying `val`. Default: `false`
//   distance = When parting out, use `distance` to specify how far away to place attached elements. Default: `60`
//
// Side Effects:
//   `$idx` is set to the index number of each anchor if a list of anchors is given.  Otherwise is set to `0`.
//   `$attach_anchor` for each `from=` anchor given, this is set to the `[ANCHOR, POSITION, ORIENT, SPIN]` information for that anchor.
//   `$attach_to` is set to the value of the `to=` argument, if given.  Otherwise, `undef`
//   `$attach_norot` is set to the value of the `norot=` argument.
//   `$_anno_partno` is set to the combined value of previously set `$_anno_partno` plus the new `partno`.
//
// Continues:
//   **Parting out:** Part-numbers have a second use, in addition to providing annotation markings for models: `partno_attach()` 
//   provides a deliniation of parts within the model. Parts within the model that are delineated 
//   can be automatically expanded, parted-out, for examination or construction. This is especially 
//   useful for visualizing the internal aspects of models with that have moving parts not easily seen.
//   .
//   Part expansion applies to the entire scene, by setting `EXPAND_PARTS` within the .scad file to `true`.
//   When `EXPAND_PARTS` is set to `true`, calls to `partno_attach()` will translate its children to a 
//   new position in the scene, along the vector of their attachment. Unlike `partno()` (which places 
//   parted elements throughout the scene based on the value of the partno), `partno_attach()` negatively increases
//   the `overlap`, dragging the child along its attached vector to a position hopefully far enough away 
//   from the parent to illustrate its placement. In addition, a thin leader line is drawn between the 
//   parent and child, clarifying placement and relation.
//
// Example: `partno()`'s Example 2, above, but with using `partno_attach()`: a hirearchical part-number use, showing inheritance of the part-numbers within a tree:
//   partno(30)
//     cuboid(30) {
//       annotate(show=["partno"]);
//       partno_attach(TOP, BOTTOM, partno=16)
//         cuboid(16) {
//           annotate(show=["partno"]);
//           partno_attach(TOP, BOTTOM, partno=5)
//             cuboid(5)
//                annotate(show=["partno"]);
//         }
//     }
//
// Example: `partno()`'s Example 6, above, but with `partno_attach()`: using `$idx` as a value doesn't work with `partno_attach()` (because at the time of invocation, `$idx` isn't set correctly), but you *can* use the literal string `"idx"` as a value, and `partno_attach()` will do the right thing. This works in a distributor, and also when specifying multiple attachable anchor points in a single attach call:
//   partno(1)
//     cuboid(30)
//       partno_attach([TOP,BOTTOM,LEFT,RIGHT,FWD,BACK], BOTTOM, partno="idx")
//         sphere(r=3)
//           annotate(show=["partno"], anchor=TOP, leader_len=3);
//
//
// Example: a simple `partno_attach()` relation, with `EXPAND_PARTS` set as `false` (which is the default):
//   EXPAND_PARTS = false;
//   label("A")
//       tube(id=4, od=8, h=5) {
//           annotate(show=["label", "partno"]);
//           partno_attach(CENTER, undef, 0, 1)
//               cyl(d=4, h=10)
//                   annotate(show=["label", "partno"]); 
//       }
//
// Example: the same `partno_attach()` relation, with expansion enabled:
//   EXPAND_PARTS = true;
//   label("A")
//       tube(id=4, od=8, h=5) {
//           annotate(show=["label", "partno"]);
//           partno_attach(CENTER, undef, 0, 1)
//               cyl(d=4, h=10)
//                   annotate(show=["label", "partno"]); 
//       }
//
// Todo:
//   leader lines between children, parents are drawn with a cylinder, itself attached to the anchor point. I'd much rather that be a dashed stroke.
//
module partno_attach(from, to, overlap, partno=undef, norot=false, start_new=false, distance=60) {
    partno_t_offset = -1 * (distance - (distance * ($t + 0.0999)));

    req_children($children);
    assert($parent_geom != undef, "No object to attach to!");
    overlap = ((overlap!=undef)? overlap : $overlap) + ((EXPAND_PARTS && _defined(partno)) ? partno_t_offset : 0);
    anchors = (is_vector(from)||is_string(from))? [from] : from;
    for ($idx = idx(anchors)) {
        $_anno_partno = _partno_attach_partno_or_idx(partno, $idx, start_new);
        anchr = anchors[$idx];
        anch = _find_anchor(anchr, $parent_geom);
        two_d = _attach_geom_2d($parent_geom);
        $attach_to = to;
        $attach_anchor = anch;
        $attach_norot = norot;
        olap = two_d? [0,-overlap,0] : [0,0,-overlap];
        if (norot || (norm(anch[2]-UP)<1e-9 && anch[3]==0)) {
            translate(anch[1]) translate(olap) children();
        } else {
            fromvec = two_d? BACK : UP;
            translate(anch[1]) rot(anch[3],from=fromvec,to=anch[2]) translate(olap) children();
        }

        /// TODO: I like this a lot better; however, when from and to are both CENTER, 
        ///       it behaves badly. (probably happens when from and to are identical for 
        ///       both parent and child.)
        ///if (EXPAND_PARTS && ok_to_annotate()) {
        ///    pr = [anch[1], move(anch[2] * abs(overlap * 0.1), p=anch[1])];
        ///    part_path = line_extend(pr, tail_ext=abs(overlap * 0.9));
        ///    color("black", alpha=0.3)
        ///        dashed_stroke(part_path, [10, 2, 3, 2, 3, 2], width=0.3, closed=false);
        ///}
        if (_defined(partno) && EXPAND_PARTS && ok_to_annotate()) {
            fromvec = two_d ? BACK : UP;
            $attach_to = BOTTOM;
            translate(anch[1]) 
                rot(anch[3], from=fromvec, to=anch[2])
                    color("black", alpha=0.3) 
                        cyl(d=0.3, l=abs(overlap));
        }
    }
}

/// Function: _partno_attach_partno_or_idx()
/// Synopsis: generates a suitable partno for elements within partno_attach()
/// Usage:
///   partno = _partno_attach_partno_or_idx(partno, idx, start_new);
/// Description:
///   Given a user-provided part-number `partno`, an index value of attachable elements `idx` (basically 
///   the same thing as `$idx`), and a boolean `start_new`, returns a partno value suitable 
///   for storing in `$_anno_partno`.  
///   This function exists to conditionally use an `attach()` managed `$idx` value in place 
///   of a user-specified part-number, if the user wants to. By specifying a `partno` of `"idx"` to 
///   `partno_attach()`, an `$idx` value will be used. 
///   .
///   Note this precludes the use of *ever* using the literal "idx" as a part-number component. 
///   I'm ok with that.
function _partno_attach_partno_or_idx(partno, idx, start_new=false) = 
    let(
        pn = (partno == "idx") ? idx : partno,
        apno = (!_defined(pn))
            ? $_anno_partno
            : (start_new)
                ? [pn]
                : (_defined($_anno_partno)) 
                    ? concat($_anno_partno, pn) 
                    : [pn]
    )
    apno;





// Module: spec()
// Synopsis: Apply a specification annotation to a hierarchy of children modules
// Usage:
//   spec(list) [CHILDREN];
// Description:
//   Applies given `list` as a series of `[key, value]` pair specifications to all children hirearchially beneath the `spec()` call. 
//   When annotated, the specification will have its pairs displayed in a *key=value* layout. 
//
// Arguments:
//   list = A list of specifications. Specifications are *assumed* to be lists, of the `[key, value]` format. 
// 
// Continues:
//   Calling `spec()` with no `list` argument clears the presensce of the specification annotation for all 
//   subsequent children.
// 
// Todo:
//   Currently, `spec()` and `obj()` conflict with each other, and until that gets resolved, don't use them both on the same annotation.
//
// Example: a basic specification:
//  spec([["cuboid"], ["s", 10]])
//    cuboid(10)
//      annotate(show=["spec"]);
// 
// Example: explicit argument specification:
//  spec([
//      ["cuboid"], 
//      ["x", 10], ["y", 20], ["z", 8], 
//      ["anchor", CENTER]
//      ])
//    cuboid([10, 20, 8], anchor=CENTER)
//      annotate(show=["spec"]);
// 
module spec(list) {
    $_anno_spec = list;
    children();
}


// Module: obj()
// Synopsis: Apply an Object annotation to a hierarchy of children modules
// Usage:
//   obj(object) [CHILDREN];
// Description:
//   Applies given `object` as a model specification to all children hirearchically beneath the `obj()` call. 
//   When annotated, the object will have its attributes and values displayed in a *key=value* layout. 
//
// Arguments:
//   object = An object of any type. 
//
// Continues: 
//   Object modules *should* call `obj()` with their own object entries immediately before calling `attachable()`, 
//   to prevent accidental hierarchical transfer of objects when it's not desired. 
//   .
//   Calling `obj()` with no `object` argument clears the presence of the object annotation 
//   for subsequent children.
//
// Todo:
//   Currently, `spec()` and `obj()` conflict with each other, and until that gets resolved, don't use them both on the same annotation.
//   obj() documentation is lacking, only because I don't feel like providing a mythical Object handler. 507common has the best examples, it'll be clearer in that repo.
//
module obj(obj=[], dimensions=[], flyouts=[]) {
    log_info_if(( !_defined(obj) && !_defined(dimensions) && !_defined(flyouts) ), 
        "obj(): no Object, dimensions, or flyouts specified. Obj, dimension settings for subsequent children will be emptied.");
    $_anno_obj = obj;
    $_anno_obj_measure = [ dimensions, flyouts ];
    children();
}


// Section: Annotating Modules
//   Labeling and describing shapes and models with Annotations happens in two steps. The first step applies the annotation; 
//   the second step produces the in-scene textual elements applied to the shape, the actual act of annotation, where the 
//   various labels and tags are assembled into a flyout that provides context to the viewer as to what exactly they're 
//   looking at.
//   .
//   The modules in this section do the second step: they pull together the locally-scoped variables, create a text block with 
//   all the relevant and selected annotations, and drop it in-scene with a flyout attached to the shape or model. 
//
// Module: annotate()
// Synopsis: Annotate a shape or model within scene
// Usage:
//   [ATTACHABLE] annotate();
//   [ATTACHABLE] annotate(<desc>, <show=["label", "desc"]>, <anchor=RIGHT>, <label=undef>, <partno=undef>, <spec=undef>, <obj=undef>, <leader_len=30>, <color=undef>, <alpha=undef>);
//
// Description:
//   When called as a child to an attachable element, `annotate()` creates a flyout block of text 
//   using scoped variables to describe the element being annotated. Text and flyout leader lines from 
//   `annotate()` are shown while previewing models (as when a scene is shown using the Preview function, or by 
//   using `<F5>`). Annotations are not generated during a proper render (as when using `<F6>`): if annotations 
//   are needed within the scene in a render, set `RENDER_ANNOTATIONS` to `true` somewhere within your .scad file.
//   .
//   Annotation types displayed can be selected by passing a list via the `show` argument; valid types of annotation are 
//   `label`, `partno`, `spec`, `obj`, and `desc`. The `show` argument will also accept the string `ALL`, to display all 
//   annotation types, as well as `NONE`, to show none. By default, `label` and `desc` will be shown, if they are set.
// Figure: supported annotation types shown in the flyout below: a `label` of `L`, a singular `partno` of `001`, a `desc` set to `descriptive text`, a `spec`, and an `obj`:
//   sphere(0.0001)
//   annotate(
//     "Description text",
//     label="L", partno="001", 
//     spec=[["Specification"], ["key", "value"], 
//       ["key2", 2], ["bool", false], 
//       ["listing", [1, 2]]],
//     obj=Object("Generic Object", ["k1=i", "k2=i"], ["k1", 12, "k2", 6]),
//     show=["ALL"],
//     leader_len=10
//     );
//
// Continues:
//   These flyouts are connected to their parent model via a leader-line. The leader-line attaches to the anchor point on the parent 
//   as set by the `anchor` argument given to `annotate()`. If there isn't an `anchor` specified, `annotate()` will use `RIGHT`. 
//   The leader-line length can be adjusted with the `leader_len` argument. 
//   Flyouts are constructed in the `color` color, with their transparency set with `alpha`. 
//
// Arguments:
//   desc = An optional description that only applies to this annotation text block. No default. 
//   ---
//   show = A list of annotation types to display, if there is a value for them. Default: `["label", "desc"]`
//   anchor = A named standard anchor **on the parent** to the `annotate()` call. Default: `RIGHT`
//   label = Sets a label if one is not already set within the child hirearchy above this `annotate()` call. No default. 
//   partno = Sets a part-number if one is not already set within the child hirearchy above this `annotate()` call. No default. 
//   spec = Sets a specification list if one is not already set within the child hirearchy above this `annotate()` call. No default. 
//   obj = Sets an object if one is not already set within the child hirearchy above this `annotate()` call. No default. 
//   leader_len = Defines the length of the leader lines used for flyouts. Default: `30`
//   color = Sets the color the annotation is displayed in. Default: `black`
//   alpha = Sets the transparency the annotation is displayed with. Default: `0.5`
//
// Continues:
//   Orientation is an oddly-solved problem for annotation models that are attached to parents.
//   `annotate()` takes steps to keep the text oriented forward to the default viewport, towards the negative Y-axis
//   or `FWD`. Those steps try to step in when the parent's orientation is other than `UP`: for 
//   example, if the parent's orientation is `FWD`, the annotation's orientation is adjusted to 
//   `BACK`, to keep the text viewable. This activity breaks down a little when parent orientation 
//   is a combination, such as `TOP+RIGHT`. This activity breaks down completely when the parent 
//   rotated after it and the annotation is rendered: avoid doing that.
//
//
// Example: A simple annotation with just a label:
//   label("A")
//     cuboid(10)
//       annotate();
//
// Example: Same as Example 1, but with some descriptive text:
//   label("A")
//     cuboid(10)
//       annotate("critical part");
//
// Example: Annotating a part with its inherited part-numbers, and its label `A`, and the `MECH_NUMBER` for the entire model `EX`:
//   label("A")
//     partno("01")
//       cuboid(10)
//         attach(BOTTOM, TOP)
//           partno("01")
//             cuboid(20)
//               annotate(show=["ALL"]);
//
// Example: Excluding annotation types from being annotated, even if they are present, won't show them. In this case, only the part-number is shown:
//   label("A")
//     partno(10)
//       cuboid(10)
//         annotate(show=["partno"]);
//
// Example: If none of the annotations selected to be shown have values, no annotation flyout will be created:
//   label("A")
//     cuboid(10)
//       annotate(show=["partno"]);
//
/// Example: As the parent orientation changes, so does the positioning of the parent. `annotate()` will reposition and reorient its flyout text to remain consitently oriented towards `FWD`:
///   xdistribute(spacing=60) {
///      ydistribute(spacing=60) {
///         label("A") cyl(d=30, h=30, orient=UP)   annotate("bcdef");
///         label("A") cyl(d=30, h=30, orient=DOWN) annotate("bcdef");
///         label("A") cyl(d=30, h=30, orient=LEFT) annotate("bcdef");
///      }
///      ydistribute(spacing=40) {
///         label("A") cyl(d=30, h=30, orient=RIGHT) annotate("bcdef");
///         label("A") cyl(d=30, h=30, orient=FWD)   annotate("bcdef");
///         label("A") cyl(d=30, h=30, orient=BACK)  annotate("bcdef");    
///      }
///   }
//
// Todo:
//    gotta document behavior on orientation vs rotation with flyouts.
//    The default of blocks to be shown should be "ALL", and `show` should exist to *limit* what is shown.
//    obj() documentation is lacking, only because I don't feel like providing a mythical Object handler. 507common has the best examples, it'll be clearer in that repo.
//
module annotate(desc, show=["label", "desc"], label=undef, partno=[], spec=undef, obj=undef, anchor=RIGHT, color=undef, alpha=undef, leader_len=undef) {
    supported_annos = ["label", "partno", "spec", "obj", "desc"];
    show_ = (is_list(show))
        ? (in_list("ALL", show))
            ? supported_annos
            : (in_list("NONE", show))
                ? []
                : set_intersection(show, supported_annos)
        : (show == "ALL")
            ? supported_annos
            : (show == "NONE")
                ? []
                : (in_list(show, supported_annos))
                    ? [show]
                    : log_warning_assign([show], ["Unclear value for `show`:", show, "; treating this as a valid annotation type as-is"]);

    // build an Annotation object with what we know from scope-specific variables passed down to us:
    anno_ = Annotation([
            "label",  _first([label,  $_anno_labelname]),
            "partno", _first([partno, $_anno_partno]), // but look below: we reassign this attr later
            "spec",   _first([spec,   $_anno_spec]),
            "obj",    _first([obj,    $_anno_obj]),
            "desc",   _first([desc,   $_anno_desc]),
            "color",  color,
            "alpha",  alpha,
            "leader_len", leader_len
            ]);
    anno = (_defined(anno_partno(anno_))) ? anno_assemble_partno(anno_) : anno_;

    // list out the known blocks, but only for the ones we asked for:
    blocks = set_intersection(anno_active_block_headers(anno), show_);

    if (_defined(blocks) && ok_to_annotate()) {
        // figure out where, how to place this annotation object:
        // `$parent_geom` is set by BOSL2's attachable() module. 
        // `find_anchor()` is provided by BOSL2. 
        parent_anchor = _find_anchor(anchor, $parent_geom);
        // The attachment face for the parent 
        // is at parent_anchor[1]. You can illustrate this 
        // with: `translate(parent_anchor[1]) color("red") sphere(r=2);`

        // a tuple of: [ text-or-list-to-model,  size-of-text ]
        text_sections = list_remove_values([
            (in_list("label", blocks))
                ? [ [anno_label(anno)], 
                    anno_size_for_attr("label"), ] 
                : undef,
            (in_list("partno", blocks))
                ? [ [anno_partno(anno)], 
                    anno_size_for_attr("partno"),] 
                : undef,
            (in_list("desc", blocks))
                ? [ [anno_desc(anno)], 
                    anno_size_for_attr("desc"),] 
                : undef,
            (in_list("spec", blocks))
                ? [ anno_list_to_block(anno_spec(anno)), 
                    anno_size_for_attr("spec"),] 
                : undef,
            (in_list("obj", blocks))
                ? [ anno_obj_to_block(anno_obj(anno)), 
                    anno_size_for_attr("obj"),] 
                : undef
            ], undef, all=true);

        text_block_heights = [ 
            for (i=idx(text_sections)) 
                attachable_text3d_boundary(text_sections[i][0], size=text_sections[i][1]).y 
            ];
        cumulative_heights = [ 
            for (i=idx(text_sections)) 
                (i > 0) ? sum(select(text_block_heights, 0, i-1)) : 0 
            ];

        translate(parent_anchor[1])
            sphere(r=0.00001)
                attach(TOP, "flyout-point")
                    flyout(color=anno_color(anno), leader=anno_leader_len(anno))
                        attach("flyout-text", LEFT)
                            color(anno_color(anno))
                                attachable_text3d_multisize(text_sections);
    }
}

/// ----------------------------------------------------------------------------------
/// Function: anno_assemble_partno()
/// Synopsis: Assemble a complete partno string
/// Usage:
///   anno_obj = anno_assemble_partno(anno);
///
/// Description:
///   Given an Annotation object `anno`, build a full part-number string 
///   based on all the elements that go into the part-number, 
///   set that to the Object's `partno` attribute and return an 
///   entirely new Annotation object `anno_obj`. The existing Annotation 
///   object is unmodified. 
///
/// Arguments:
///   anno = An Annotation object
///   
/// Todo:
///   Grr - sure would be swell if we could automatically detect the use of `$idx` here without openscad barfing all over us. Yeap. 
///   this... may not be fully operational. there's a lot going on here and I'm not sure this will work in all cases. It seems to meet our needs today.
///
function anno_assemble_partno(anno) = 
    let(
        partno_ = anno_partno(anno),
        m_flat = anno_partno_sequence(anno),
        nv = (_defined(m_flat) && _defined(partno_)) ? str_join(m_flat, "-") : undef
    )
    anno_partno(anno, nv=nv);

function anno_partno_sequence(anno) = 
    let(
        mech_num_ = anno_mech_number(anno),
        partno_ = anno_partno(anno),
        label_ = anno_label(anno),
        mm = flatten([
            mech_num_, 
            (_defined(label_))  ? label_           : undef,
            (_defined(partno_)) ? flatten(partno_) : undef
            ])
    ) 
    list_remove_values(mm, undef, all=true);


/// Function: anno_active_block_headers()
/// Synopsis: Return a list of annotation blocks that have values
/// Usage:
///   list = anno_active_block_headers(anno);
///
/// Description:
///   Given an Annotation object `anno`, examine the attributes that make up 
///   the Annotation to be displayed, and return a list of those 
///   blocks `list`.
///   Annotation attributes that do not have a value set will not be 
///   represented in `list`.
///
/// Arguments:
///   anno = An Annotation object
///
function anno_active_block_headers(anno) = 
    list_remove_values([
        (_defined( anno_label(anno)  )) ? "label"  : undef,
        (_defined( anno_partno(anno) )) ? "partno" : undef,
        (_defined( anno_desc(anno)   )) ? "desc"   : undef,
        (_defined( anno_spec(anno)   )) ? "spec"   : undef,
        (_defined( anno_obj(anno)    )) ? "obj"    : undef
        ], undef, all=true);
        

/// Function: anno_size_for_attr()
/// Synopsis: Return a font-size based on an annotation attribute name
/// Usage:
///   size = anno_size_for_attr(attr);
/// 
/// Description:
///   Given an attribute name `attr`, return the expected font-size for that 
///   attribute name `size`. `size` is an integer of a suitable 
///   size for reading text applicable for `attr`. 
///
/// Arguments:
///   attr = An attribute name
///
/// Todo:
///   the static fallback of `3` should be a FileLib constant, and values should derive from that.
///
function anno_size_for_attr(attr) = (attr == "label") ? 7 : (attr == "partno") ? 5 : 3;


/// Function: anno_obj_to_block()
/// Synopsis: Convert an Annotation object to a block of text
/// Usage:
///   block = anno_obj_to_block(obj);
///
/// Description:
///   Given an Object `obj`, construct a list of lists detailing the Object and its 
///   attributes, and return it as a list `block`. The resulting `block` will have 
///   a single-element list at its first position detailing the Object's TOC type, 
///   followed by one or more `[attr, value]` pairs of lists. 
///
/// Arguments:
///   obj = An Object, of any type
///
/// Example:
///   a = Axle();
///   block = anno_obj_to_block(a);
///   // block == [ ["Axle"], ["diameter", 0], ["length", 0] ];
///
function anno_obj_to_block(obj) = anno_list_to_block([
    [obj_toc_get_type(obj)],
    for (name=obj_toc_get_attr_names(obj)) 
        if (name != "_toc_" && _defined(obj_accessor_get(obj, name, _consider_toc_default_values=false)))
            [ name, ( (obj_is_obj(obj_accessor_get(obj, name, _consider_toc_default_values=false))) 
                ? "[object]" 
                : obj_accessor_get(obj, name, _consider_toc_default_values=false) ) ] 
    ]);


/// Function: anno_list_to_block()
/// Synopsis: Convert an list to a block of text
/// Usage:
///   block = anno_list_to_block(list);
///
/// Description:
///   Given a list of elements `list`, return a list of 
///   elements that are suitable for annotation. Lists that 
///   are standalone, having only one element within them, are 
///   returned asis; lists that have multiple elements within them 
///   are converted to strings, joined with an equal sign `=`. 
///   .
///   This can be characterized as a poor-man's `flatten()`, with 
///   additional formatting added.
///
/// Arguments:
///   list = A list
///
/// Example:
///   m = anno_list_to_block(["a", "b", ["c", 1], "d", ["e", "E"]]);
///   // m == [ "a", "b", "c=1", "d", "e=E" ]
function anno_list_to_block(list) = [
    for (i=idx(list)) (is_list(list[i])) ? str_join(list[i], "=") : list[i]
    ];




/// Function: partno2translate()
/// Synopsis: Transform an annotation part-number to a 3D point for positioning
/// Usage:
///   xyz_offset = partno2translate();
///   xyz_offset = partno2translate(<d=30>);
/// Description:
///   Provide a translatable set of XYZ coordinates. 
///   Position selection is obtained from the actively 
///   set partno part-number. 
///   .
///   Each sequence in the part number is converted to 
///   its binary representation, then xor'd together. 
///   The sequence is used to create a positional offset.
/// Arguments:
///   ---
///   d = Value used for distancing individual steps of movement. Default: `30`
///
function partno2translate(d=50) =
    let(
        anno = anno_assemble_partno(
            Annotation([
                "label", $_anno_labelname,
                "partno", $_anno_partno
                ])),
        x = [ for (i=anno_partno_sequence(anno)) 
                bin2vec( multi_bw_xor(str2bin(i)) ) ]
    ) rec_mat(x, d);


/// Function: rec_mat()
/// Usage:
///   v = rec_mat(vectors, distance);
/// Description:
///   Given a list of directions `vectors` and a distance value `distance`, 
///   apply each as a `move()` activity and return the 
///   resulting positional point as a vector list `v`.
/// Arguments:
///   vectors = A list of one or more vectors (not positions). No default
///   distance = A distance value to apply to each vector direction in `vectors`. No default
/// Continues:
///   It is an error to specify an empty list of vectors.
///   .
///   It is not an error to not specify a `distance`, but perhaps it should be.
function rec_mat(vectors, distance) =
    assert(len(vectors) > 0)
    let(
        u = vectors[0] * distance,
        v = (len(vectors) > 1)
            ? move( u, p=rec_mat(select(vectors, 1, -1), distance))
            : move( u, p=[0,0,0] )
    ) v;


/// Function: bin2vec()
/// Synopsis: Translate a binary value to a vector
/// Usage:
///   v = bin2vec(b);
/// Description:
///   Given a single byte as a list of bits `b`, return 
///   a vector direction that represents that byte: 
///   LSBs 7, 6, & 5 are are used for x, y z vectors; 
///   their direction is dictated by LSBs 4, 3, & 2, respectively. 
///   Bits 1 and 0 are not used at this time. 
/// Arguments:
///   b = A list of eight bits to convert. No default
/// Continues:
///   It is an error to specify a byte `b` that is not eight bits long.
function bin2vec(b) = 
    assert(len(b) == 8)
    let(
        v = [
            b[7] * ((b[4] == 0) ? -1 : 1),
            b[6] * ((b[3] == 0) ? -1 : 1),
            b[5] * ((b[2] == 0) ? -1 : 1),
            ]
    ) v;


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


/// Infoblocks
module infoblock(v=10, color="red", symbol=undef, font="Liberation Sans") {
    module _shell(s) {
        diff("remove")
            intersect("os")
                cube(s, anchor=CENTER)
                    attach(CENTER, CENTER)
                        tag("os") sphere(d=s * 1.45)
                            attach(CENTER, CENTER)
                                tag("remove") sphere(d=s * 1.42);
    }
    difference() {
        union() {
            color(color, alpha=0.3)
                _shell(v);
            if (_defined(symbol)) 
                color(color)
                    rot_copies([[90,0,0],[0,90,0],[0,0,90]])
                        text3d(symbol, size=v * 0.7, h=v * 1.05, font=font, orient=FWD, anchor=CENTER);

        }
        color(color, alpha=0.3)
            cube(v * 0.9, anchor=CENTER);
    }
}


module infoblock_info(s=10) {
    if (ok_to_annotate())
        attachable(CENTER, 0, UP, size=[s,s,s]) {
            infoblock(s, color="yellow", font="Webdings", symbol="i");
            children();
        }
}

module infoblock_ok(s=10) {
    if (ok_to_annotate())
        attachable(CENTER, 0, UP, size=[s,s,s]) {
            infoblock(s, color="green", font="Webdings", symbol="a");
            children();
        }
}

module infoblock_notok(s=10) {
    if (ok_to_annotate())
        attachable(CENTER, 0, UP, size=[s,s,s]) {
            infoblock(s, color="red", font="Webdings", symbol="x");
            children();
        }
}

/// ----------------------------------------------------------------------------------
/// Section: Annotation Object Functions
///   These functions leverage the OpenSCAD Object library to create an Annotation Object and its attribute accessors.
///   See https://github.com/jon-gilbert/openscad_objects/blob/main/docs/HOWTO.md for a quick primer on constructing and 
///   using Objects; and https://github.com/jon-gilbert/openscad_objects/wiki for 
///   details on Object functions. 
/// 
/// Subsection: Construction
/// 
/// Function: Annotation()
/// Description:
///   Given either a variable list of attributes and values, or an existing object from 
///   from which to mutate, constructs a new `annotation` object list and return it. 
///   .
///   `Annotation()` returns a list containing an opaque object. See `Object()` in https://github.com/jon-gilbert/openscad_objects/wiki.
/// Usage:
///   obj = Annotation();
///   obj = Annotation(vlist);
///   obj = Annotation(vlist, mutate=obj);
/// Arguments:
///   ---
///   vlist = Variable list of attributes and values, eg: `[["length", 10], ["style", undef]]`. Default: `[]`. 
///   mutate = An existing `anno` object on which to pre-set object values. Default: `[]`. 
/// Example:
///   anno = Annotation();
function Annotation(vlist=[], mutate=[]) = Object("Annotation", Annotation_attrs, vlist=vlist, mutate=mutate);

/// Constant: Annotate_attributes
/// Description:
///   A list of all `anno` attributes.
/// Attributes:
///   mech_number = s = The mechanism number of the model, eg `001`, as a string. Default: the value of `MECH_NUMBER`
///   label = s = The "label" of the model, eg `A` as in "Part A, slot B", and so on. Labels are hierarchally applied. No default.
///   partno = s = The part-number of the model. Part-numbers automatically have the object's `mech_number` prefixed. Part-numbers are cumulative hierarchally. No default.
///   spec = l = A list of `[key, value]` pairs that describe the model. No default.
///   obj = o = An Object of any type that produced the model. No default.
///   desc = s = A freeform description of the model. No default.
///   color = s = The color to use when annotating models. Default: `black`
///   alpha = i = The alpha, or transparency used when annotating model. Default: `0.5`
///   leader_len = i = The length of leader lines that connect models to flyouts. Default: `8`
Annotation_attrs = [
    ["mech_number", "s", (!MECH_NUMBER) ? undef : MECH_NUMBER ],
    "label=s", 
    "partno=s", 
    ["spec", "l", []], 
    ["obj", "l", []], 
    "desc=s", 
    "color=s=black", 
    "alpha=s=0.5", 
    "leader_len=i=8"
    ];

/// Subsection: Attribute Accessors 
///   Each of the attributes listed in `Annotate_attributes` has an accessor built for it, a function 
///   for getting and setting the attribute's value within the Annotate object. 
///   Each of the attributes listed above has an accessor with the same syntax as `anno_label()`, below.
///
/// Function: anno_label()
/// Usage:
///   value = anno_label(anno, <default=undef>);
///   new_anno = anno_label(anno, nv=new_value);
/// Description:
///   Mutatable object accessor for the `label` attribute. Given an `anno` object, operate on that object. The operation
///   depends on what other options are passed. 
///   .
///   Calls to `anno_label()` with no additional options will look up the 
///   value of `label` within the object and return it. If a `default` option is provided to `anno_label()` and 
///   `label` is unset, the value of `default` will be returned instead. 
///   . 
///   Calls to `anno_label()` with a `nv` (new-value) option will return a wholly new Annotate object, whose 
///   `label` attribute is set to the value of `nv`. *The existing Annotate object is unmodified.*
/// Arguments:
///   anno = An Annotate object. No default. 
///   ---
///   default = If provided, and if there is no value currently set for `label`, `anno_label()` will instead return this provided value. No default. 
///   nv = If provided, `anno_label()` will return a new Annotate object with the new value set for `label`. The existing `anno` object is unmodified. No default. 
/// Continues:
///   It is not an error to call `anno_label()` with both `default` and `nv`, however if they are both defined only the `nv` "set" 
///   operation is performed. Note that setting `nv` to `undef` expecting to clear the value of `label` won't produce a new object; 
///   to clear the value of `label`, you must use `obj_accessor_unset()`. 
/// Example:
///   anno = Annotate();
///   val = anno_label(anno);
/// Example:
///   anno = Annotate();
///   new_anno = anno_label(anno, nv="L");
function anno_mech_number(obj, default=undef, nv=undef) = obj_accessor(obj, "mech_number", default=default, nv=nv);
function anno_label(obj, default=undef, nv=undef)       = obj_accessor(obj, "label", default=default, nv=nv);
function anno_partno(obj, default=undef, nv=undef)      = obj_accessor(obj, "partno", default=default, nv=nv);
function anno_spec(obj, default=undef, nv=undef)        = obj_accessor(obj, "spec", default=default, nv=nv);
function anno_obj(obj, default=undef, nv=undef)         = obj_accessor(obj, "obj", default=default, nv=nv);
function anno_desc(obj, default=undef, nv=undef)        = obj_accessor(obj, "desc", default=default, nv=nv);
function anno_color(obj, default=undef, nv=undef)       = obj_accessor(obj, "color", default=default, nv=nv);
function anno_alpha(obj, default=undef, nv=undef)       = obj_accessor(obj, "alpha", default=default, nv=nv);
function anno_leader_len(obj, default=undef, nv=undef)  = obj_accessor(obj, "leader_len", default=default, nv=nv);


