// LibFile: annotate.scad
//   Functions and modules for annotating OpenSCAD models
//   Annotations are in-scene flyout blocks of information on specific models.
//
// FileSummary: Functions and modules for annotating models
// Includes:
//   include <openscad_annotations/annotate.scad>
//   MECH_NUMBER = "EX";
// Continues:
//   *(Some aspects of annotation depend on the use of a file-wide global value 
//   `MECH_NUMBER`, which uniquely identifies the entire mechanism being 
//   modeled; eg, "002". OpenSCAD doesn't offer the facility to query the filename 
//   being operated on for reasons beyond knowing, and this variable must be set somehow. Ideally 
//   the `MECH_NUMBER` value is set in your model just after where `openscad_annotations/annotate.scad` 
//   is included, as shown here. You should set it to whatever best makes sense to your project; within 
//   this documentation, the value `"EX"` is used, to signal it is an example.)*
//

include <openscad_annotations/common.scad>
include <openscad_annotations/flyout.scad>


/// Section: Global Constants
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
/// Constant: $_EXPAND_PARTS
/// Description: 
///   Boolean variable that can instruct models using `partno()` to 
///   "part-out" their models, by expanding deliniated parts away 
///   from their modeled position. 
///   Currently: `false`
/// See Also: partno(), partno_attach()
EXPAND_PARTS = false;
$_EXPAND_PARTS = false;

/// Constant: ISOLATED_PART
/// Constant: $_ISOLATED_PART
/// Description:
///   A scalar value meant to hold a string representing a 
///   full part number. When set, only shapes with that 
///   part are meant to be shown in-scene. 
///   Currently: `undef`
/// See Also: partno(), partno_attach(), _is_shown()
ISOLATED_PART = undef;
$_ISOLATED_PART = undef;

/// Constant: LIST_PARTS
/// Description:
///   Boolean variable ethat can instruct models using `partno()`
///   emit part numbers to OpenSCAD's console - or STDOUT when 
///   run non-interactively - as they are discovered. 
///   Currently: `false`
/// See Also: partno(), partno_attach()
LIST_PARTS = false;

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



// Section: Applying Annotations to Shapes and Modules
//   Labeling and describing shapes and models with Annotations happens in two steps. The first step applies the annotation, 
//   be it a simple label ("tab-A"), a descriptive block of text ("fits into slot B"), a part-number ("A-001-X"), or 
//   whatever; the second step produces the in-scene textual elements applied to the shape, the actual act of annotation.
//   .
//   The modules in this section do the first step: they apply the notes and annotation to child shapes and models, to be 
//   rendered into an annotation in the next step.
//
// Function&Module: label()
// Synopsis: Return or apply a label annotation to a hierarchy of children modules
// Usage: as a function:
//   str = label();
// Usage: as a module:
//   label(name) [CHILDREN];
// Description:
//   Applies `name` as a label. A label is a simple, discrete name useful in directions or 
//   explanations, such as "tab A" or "slot B". When annotated, labels have the largest and 
//   most prominent display.
//   .
//   Label assignment is hierarchical, in that all children beneath the `label()` call will 
//   have the same label. Label assignment is singular, in that there is only ever 
//   one label assigned to a 3D element when annotated. 
//   .
//   When invoked as a function, `label()` returns the current hierarchical label `str`.
// 
// Arguments:
//   name = A string to set as the label for all child elements. 
//
// Continues: 
//   Invoking `label()` as a module with no `name` argument clears the presence of a label annotation 
//   for subsequent children. Invoking `label()` as a function with a `name` argument makes no changes.
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
function label(name=undef) = $_anno_labelname;

module label(name) {
    req_children($children);
    $_anno_labelname = name;
    children();
}

// Function&Module: desc()
// Synopsis: Return or apply a description annotation to a hierarchy of children modules
// Usage: as a function:
//   str = desc();
// Usage: as a module:
//   desc(desc) [CHILDREN];
// Description:
//   Applies `desc` as a description. A description is additional context, a few short words.
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
//   .
//   When invoked as a function, `desc()` returns the current hierarchical description `str`.
// 
// Arguments:
//   desc = A string to set as the desc for all child elements. 
//
// Continues: 
//   Invoking `desc()` as a module with no `desc` argument clears the presence of a label annotation 
//   for subsequent children. Invoking `desc()` as a function with a `desc` argument makes no changes.
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
function desc(desc=undef) = $_anno_desc;

module desc(desc) {
    req_children($children);
    $_anno_desc = desc;
    children();
}


// Function&Module: spec()
// Synopsis: Return or apply a specification annotation to a hierarchy of children modules
// Usage: as a function:
//   list = spec();
// Usage: as a module:
//   spec(list) [CHILDREN];
// Description:
//   Applies given `list` as a series of `[key, value]` pair specifications to all children hirearchially beneath the `spec()` call. 
//   When annotated, the specification will have its pairs displayed in a *key=value* layout. 
//   .
//   When invoked as a function, `spec()` returns the current specification `list`.
//
// Arguments:
//   list = A list of specifications. Specifications are *assumed* to be lists, of the `[key, value]` format. 
// 
// Continues:
//   Invoking `spec()` as a module with no `list` argument clears the presensce of the specification annotation for all 
//   subsequent children. Invoking `spec()` as a function with a `list` argument makes no changes.
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
function spec(list=undef) = $_anno_spec;

module spec(list) {
    req_children($children);
    $_anno_spec = list;
    children();
}


// Function&Module: obj()
// Synopsis: Apply an Object annotation to a hierarchy of children modules
// Usage: as a function:
//   object = obj();
// Usage: as a module:
//   obj(object) [CHILDREN];
// Description:
//   Applies given `object` as a model specification to all children hirearchically beneath the `obj()` call. 
//   When annotated, the object will have its attributes and values displayed in a *key=value* layout. 
//   .
//   When invoked as a function, `obj()` returns the current hierarchical object `object`.
//   .
//   A openscad_object Object of any type can be used. You'll want to review 
//   [the documentation on Objects](https://github.com/jon-gilbert/openscad_objects/wiki) for 
//   more information on how these work.
//
// Arguments:
//   object = An object of any type. 
//
// Continues: 
//   Object modules *should* call `obj()` with their own object entries immediately before calling `attachable()`, 
//   to prevent accidental hierarchical transfer of objects when it's not desired. 
//   .
//   Invoking `obj()` as a module with no `object` argument clears the presence of the object annotation 
//   for subsequent children. Invoking `obj()` as a function with an `object` argument makes no changes.
//
// Todo:
//   Double-check that `spec()` and `obj()` no longer conflict with each other
//   `obj()` example documentation is lacking
//
function obj(obj=undef, dimensions=undef, flyouts=undef) = $_anno_obj;

module obj(obj=[], dimensions=[], flyouts=[]) {
    req_children($children);
    log_info_if(( !_defined(obj) && !_defined(dimensions) && !_defined(flyouts) ), 
        "obj(): no Object, dimensions, or flyouts specified. Obj, dimension settings for subsequent children will be emptied.");
    $_anno_obj = obj;
    $_anno_obj_measure = [ dimensions, flyouts ];
    children();
}


// Section: Annotating Part Numbers, and Parting Out Modules
//   A part-number is an identifier for discrete sub-sections of a model. Part-numbers are 
//   hirearchical and cumulatively collected, implying a chain of parentage. Specifying part 
//   numbers for models works roughly the same as labels and descriptions, in that a module 
//   sets a value for the hierarchy underneath it. What differes is that part numbers stack 
//   hierarchically, and allow parts of models to be arranged apart from each other to ease 
//   inspection of complex pieces. 
// Figure(3D,NoAxes,NoScales): A relatively simple-complex model with individually-parted models within it: a plate with a hole, in which a screw with a nut is inserted. In the scene, neither the screw's nut, nor the plate's hole, can be easily examined.
//   include <BOSL2/screws.scad>
//   partno(1)
//    diff()
//      cuboid([20, 20, 3])
//        tag("remove") attach(CENTER) cyl(d=5, h=4);
//   partno(2)
//    screw("M5,8", thread_len=5, head="button", drive="torx", anchor="shank_center")
//       partno_attach(BOTTOM, overlap=5, partno=1)
//         nut("M5");
//
// Continues:
//   A fully-collected part-number has a mechanical number, an optional label, and one or more part numbers, 
//   all separated with hyphens. It's akin to the following format: 
//   ```
//   partno = mech-number, [ sep, label ], sep, part-number, { sep, part-number } ;
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
//   being operated on for reasons beyond knowing, and this variable must be set somehow.) Ideally 
//   the `MECH_NUMBER` value is set in your model just after where `openscad_annotations/annotate.scad` is included.)*
//   .
//   When annotated, a model or shape with a part-number assigned will have the part-number in-scene as a flyout to the respective 
//   model.
// Figure(3D,NoAxes,NoScales): The model above, but with its part numbers annotated:
//   include <BOSL2/screws.scad>
//   partno(1)
//    diff()
//      cuboid([20, 20, 3]) {
//        annotate(show=["partno"], anchor=BACK);
//        tag("remove") attach(CENTER) cyl(d=5, h=4);
//        }
//   partno(2)
//    screw("M5,8", thread_len=5, head="button", drive="torx", anchor="shank_center") {
//       annotate(show=["partno"]);
//       partno_attach(BOTTOM, TOP, overlap=5, partno=1)
//         nut("M5")
//           annotate(show=["partno"]);
//    }
//
// Continues:
//   .
//   **Parting out:** Both `partno()` and `partno_attach()` below provide 
//   a deliniation of parts within the model. Parts within the model that are delineated 
//   can be automatically expanded, parted-out, for examination or construction. This is especially 
//   useful for visualizing the internal aspects of models with that have moving parts not easily seen.
//   The distances between parts is adjusted by the current value of `$t`, and animating the scene
//   within OpenSCAD will produce parts that coalesce into place over time.
//   .
//   Part expansion applies to the entire scene, by setting `EXPAND_PARTS` within the .scad file to `true`;
//   or within a partial subset of the scene by using `expand_parts()`.
// Figure(3D,NoAxes,NoScales): The above example model, but with part expansion enabled:
//   include <BOSL2/screws.scad>
//   EXPAND_PARTS = true;
//   partno(1)
//    diff()
//      cuboid([20, 20, 3])
//        tag("remove") attach(CENTER) cyl(d=5, h=4);
//   partno(2)
//    screw("M5,8", thread_len=5, head="button", drive="torx", anchor="shank_center")
//       partno_attach(BOTTOM, overlap=5, partno=1)
//         nut("M5");
//
// Continues:
//   .
//   **Highlighting Parts:** Individual parts can be isolated and selectively displayed by setting
//   the `ISOLATED_PART` global variable, or by calling the `isolated_part()` module somewhere in the 
//   hirearchy. This will exclude all but the specified part number when producing models. 
//   .
//   If you're unsure what parts are available for isolating, or if you're running openscad 
//   non-interactively, you can set `LIST_PARTS` to `true`: it will emit all the parts found 
//   as it produces the scene to STDOUT (or to the console, if run within the GUI). 
// Figure(3D,NoAxes,NoScales): The above example model again, but this time with only part `EX-2` (the screw) shown:
//   include <BOSL2/screws.scad>
//   ISOLATED_PART = "EX-2";
//   partno(1)
//    diff()
//      cuboid([20, 20, 3])
//        tag("remove") attach(CENTER) cyl(d=5, h=4);
//   partno(2)
//    screw("M5,8", thread_len=5, head="button", drive="torx", anchor="shank_center")
//       partno_attach(BOTTOM, overlap=5, partno=1)
//         nut("M5");
//
//
// Function&Module: partno()
// Synopsis: Return or apply a part-number annotation to a hierarchy of children modules
// Usage: as a function:
//   partno_str = partno();
//   partno_lst = partno(as_string=false);
// Usage: as a module:
//   partno(partno) [CHILDREN];
// Description:
//   When invoked as a function, `partno()` returns the current active part-number string `partno_str` 
//   from the child hierarchy. When the option `as_string` is set to `false`, the value returned is 
//   a list of all the part number elements `partno_lst`.
//   .
//   When invoked as a module, `partno()` sets or extends the model's part-numbers by appending
//   `partno` to the existing part-numbers to all children hirearchically beneath the `partno()` call. 
//   Calling `partno()` multiple times in a child hirearchy will add each call's `partno` to the part-number 
//   element list. 
//   .
//   When `EXPAND_PARTS` is set to `true`, calls to `partno()` will translate its children to a 
//   new position in the scene. The position is derived *from* the part-number, and should reasonably
//   relocate deliniated parts via `move()` so that inspection or construction is eased. The `distance` 
//   argument controls how far each step away from a part's origin to move the part; the number of steps 
//   is derived in part by how many part number sequences there are (so, part `1-1` would probably be closer to 
//   the part's origin than `1-1-1-1-1` would be).
//   .
//   When `LIST_PARTS` is set to `true`, `partno()` will emit part numbers to the console, or to STDOUT, as 
//   it is called throughout the hirearchy. 
//
// Arguments: when invoked as a function:
//   ---
//   as_string = A boolean flag that, when set, instructs `partno()` to return the part number as a string. Default: `true`
//
// Arguments: when invoked as a module:
//   partno = A string to append to the current part numbers. 
//   start_new = A boolean which, if set to `true`, clears previous part numbers from the hirearchy before applying `partno`. Default: `false`
//   distance = When parting out, use `distance` to specify how far each step away from their origin to place elements. Default: `20`
//
// Continues:
//   It is an error to invoke `partno()` as a function with any of the module-specific arguments; and, it is an 
//   error to invoke `partno()` as a module with any of the function-specific arguments.
//   .
//   There is no way for `partno()` to be aware of duplicate part numbers; and, there is every possibility that 
//   modules' echos will be called multiple times; therefore when using `LIST_PARTS`-triggered part listings, you  
//   will probably want to de-duplicate part numbers before programmatically iterating through them.
//
// See Also: partno_attach(), expand_parts(), collapse_parts(), isolate_part(), isolated_part()
//
// Example(NORENDER): setting a chain of part-numbers, and then echoing it to the console:
//   partno(1)
//    partno(1)
//     partno(2)
//      partno("4a")
//       partno(5)
//        echo(partno());
//   // yields: ECHO: "EX-1-1-2-4a-5"
//
// Example(NORENDER): setting a chain of part-numbers, resetting it in the middle, and then echoing it to the console as a list, not a string:
//   partno(1)
//    partno(1)
//     partno(2)
//      partno("4a", start_new=true)
//       partno(5)
//        echo(partno(as_string=false));
//   // yields: ECHO: ["EX", "4a", 5]
//
// Example: a simple `partno()` module example: the cube is part number `1`, and is annotated to show the same:
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
function partno(partno=undef, start_new=undef, distance=undef, anno=Annotation(), as_string=true) =
    let(
        _ = log_error_if((_defined(partno) || _defined(start_new) || _defined(distance)), 
            "When invoked as a function, partno() does not accept the `partno`, `start_new`, or `distance` arguments"),
        partno_list = anno_partno_list()
    )
    (as_string)
        ? str_join(partno_list, "-")
        : partno_list;

module partno(partno, start_new=false, distance=20, anno=undef, as_string=undef) {
    log_error_if((_defined(as_string) || _defined(anno)),
        "When invoked as a module, partno() does not accept the `as_string` argument");
    req_children($children);
    $_anno_partno = anno_partno_attach_partno_or_idx(partno, start_new=start_new);
    if (LIST_PARTS)
        echo(str("PART:", partno()));
    if (expand_parts()) {
        move(anno_partno_translate(d=distance))
            isolate_attachable_part()
                children();
    } else {
        isolate_attachable_part()
            children();
    }
}


// Module: partno_attach()
// Synopsis: attachable-aware partno() module 
// Usage:
//   [ATTACHABLE] partno_attach([attach args...], <partno=undef>, <start_new=false>, <distance=20>) [CHILDREN];
// Description:
//   `partno_attach()` combines the functionality of BOSL2's `attach()` and openscad_annotation's `partno()`. 
//   Individual models are attached to each other as normal, and in the same attach call can be assigned 
//   part numbers. When modeling two functionally distinct shapes (say, two gears) together, `partno_attach()` 
//   gives you the attachability of the pieces, while later making it easy to separate for examination, 
//   annotation, slicing, whatever. 
//   .
//   The `partno_attach()` module differs from `attach()` in the following specific four ways:
//   .
//   1. part-number assignent: when the `partno` argument is set to something, that value (a number or string) will be 
//   appended to the sequence of part numbering in the current hierarchy, as `partno()` does.
//   When parent anchors are specified as multiple vectors, using the literal `"idx"` as a `partno` will tell `partno_attach()` to use the internally 
//   generated `$idx` as the partno (but see the caveats below).
//   .
//   2. part expansion: if the `EXPAND_PARTS` global is set to `true`, `partno_attach()` will place 
//   models `distance` length away from their parents' attachment points. Unlike `partno()` which 
//   flings parts in a determinstic but unstructured direction, this relocation is determined by 
//   the attachment points. The distances are 
//   `$t`-time modified to space models away from their parents; if animated, the parts will 
//   move towards their attachments. 
//   Because attachments are specific vectors between the parent and child, `partno_attach()` can describe
//   that connection with a dashed line between the parted models; unlike `partno()`, a visual relationship
//   of how the child connects to the parent is made obvious.
//   .
//   3. part listing: if the `LIST_PARTS` global is set to `true`, `partno_attach()` will 
//   emit part numbers to the console as it finds them. If run from the command-line non-interactively, 
//   the part numbers will be emitted to STDOUT. Part numbers are emitted whether or not the 
//   child is modeled in-scene.
//   .
//   4. singular part isolating: if `ISOLATED_PART` is set to a partno-string value, `partno_attach()` 
//   works with `attachable()` to _only_ that part will be modeled in-scene. This is 
//   contingent on a re-implemention of the `_is_shown()` function, which is queried within `attachable()`.
//   The result is similar to how `show_only()` works, but without conflicting with BOSL2's tags functions.
//   .
//   The changes were kept to an absolute minimum; BOSL2's `attach()` functionality is otherwise as-is, as of 
//   2025-02-13. You'll need to review the 
//   [documentation for `attach()`](https://github.com/BelfrySCAD/BOSL2/wiki/attachments.scad#module-attach) 
//   as well as [the Attachments tutorial](https://github.com/BelfrySCAD/BOSL2/wiki/Tutorial-Attachments)
//   for a full understanding of how attachments work;
//   explaining this is outside the scope of the `partno_attach()` documentation here. You'll also need to review 
//   the documentation for `partno()` above for a full understanding of how part numbers are assigned and displayed.
//
// Arguments:
//   parent = The parent anchor point to attach to or a list of parent anchor points.
//   child = Optional child anchor point.  If given, orients the child to connect this anchor point to the parent anchor.
//   ---
//   align = If `child` is given you can specify alignment or list of alistnments to shift the child to an edge or corner of the parent. 
//   inset = Shift aligned children away from their alignment edge/corner by this amount.  Default: 0
//   overlap = Amount to sink child into the parent.  Equivalent to `down(X)` after the attach.  This defaults to the value in `$overlap`, which is `0` by default.
//   inside = If `child` is given you can set `inside=true` to attach the child to the inside of the parent for diff() operations.  Default: false
//   shiftout = Shift an inside object outward so that it overlaps all the aligned faces.  Default: 0
//   spin = Amount to rotate the parent around the axis of the parent anchor.  Can set to "align" to align the child's BACK with the parent aligned edge.  (Only permitted in 3D.)
//   partno = A string to append to the current part numbers. No default. 
//   start_new = A boolean which, if set to `true`, clears previous part numbers from the hirearchy before applying `partno`. Default: `false`
//   distance = When parting out, use `distance` to specify how far away to place attached elements. Default: `60`
//
// Side Effects:
//   `$anchor` set to the parent anchor value used for the child.
//   `$align` set to the align value used for the child.  
//   `$idx` set to a unique index for each child, increasing by alignment first.
//   `$attach_anchor` for each anchor given, this is set to the `[ANCHOR, POSITION, ORIENT, SPIN]` information for that anchor.
//   if `inside` is true and no `partno` was set then set default tag to "remove"
//   `$attach_to` is set to the value of the `child` argument, if given.  Otherwise, `undef`
//   `$edge_angle` is set to the angle of the edge if the anchor is on an edge and the parent is a prismoid or vnf with "hull" anchoring
//   `$edge_length` is set to the length of the edge if the anchor is on an edge and the parent is a prismoid or vnf with "hull" anchoring
//   `$_anno_partno` is set to the combined value of previously set `$_anno_partno` plus the new `partno`.
//
// Continues:
//   Note that because `partno_attach()` can process and apply multiple parental anchors, it can behave like a 
//   BOSL2 distributor, attaching multiple identical children to various anchors on the parent. Each of 
//   those distributed model copies is assigned an index via a `$idx` scoped variable. `partno_attach()`
//   recognizes a `partno` of `"idx"` as the signal to use `$idx` as the new part-number value. Naturally, this
//   precludes the future ability to use the literal string `"idx"` as a part number element (which is 
//   a trade-off that I'm OK with).
//   .
//   Note also there is no way for `partno_attach()` to be aware of duplicate part numbers; and, there is every possibility that 
//   modules' echos will be called multiple times; therefore when using `LIST_PARTS`-triggered part listings, you  
//   will probably want to de-duplicate part numbers before programmatically iterating through them.
//
// See Also: partno(), expand_parts(), collapse_parts(), isolate_part(), isolated_part()
//
// Example(3D): `partno()`'s Example 4, above, but with using `partno_attach()`: a hirearchical part-number use, showing inheritance of the part-numbers within a tree:
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
// Example(3D): `partno()`'s Example 8, above, but with `partno_attach()`: using `$idx` as a value doesn't work with `partno_attach()` (because at the time of invocation, `$idx` isn't set correctly), but you *can* use the literal string `"idx"` as a value, and `partno_attach()` will do the right thing. This works in a distributor, and also when specifying multiple attachable anchor points in a single attach call:
//   partno(1)
//     cuboid(30)
//       partno_attach([TOP,BOTTOM,LEFT,RIGHT,FWD,BACK], BOTTOM, partno="idx")
//         sphere(r=3)
//           annotate(show=["partno"], anchor=TOP, leader_len=3);
//
//
// Example(3D,NoAxes): a simple `partno_attach()` relation, with `EXPAND_PARTS` set as `false` (which is the default):
//   EXPAND_PARTS = false;
//   label("A")
//       tube(id=4, od=8, h=5) {
//           annotate(show=["label", "partno"]);
//           partno_attach(CENTER, undef, partno=1)
//               cyl(d=4, h=10)
//                   annotate(show=["label", "partno"]); 
//       }
//
// Example(3D,NoAxes): the same `partno_attach()` relation, with expansion enabled:
//   EXPAND_PARTS = true;
//   label("A")
//       tube(id=4, od=8, h=5) {
//           annotate(show=["label", "partno"]);
//           partno_attach(CENTER, undef, partno=1)
//               cyl(d=4, h=10)
//                   annotate(show=["label", "partno"]); 
//       }
//
// Example(3D): A sphere attached to the top of a cube, but with `ISOLATED_PART` set to limit only the sphere:
//   ISOLATED_PART = "EX-1-1";
//   partno(1)
//      cuboid(5)
//         partno_attach(TOP, BOTTOM, partno=1)
//            sphere(3);
module partno_attach(parent, child, overlap, align, spin=0, norot, inset=0, shiftout=0, inside=false, from, to, partno=undef, start_new=false, distance=20)
{
    // ## 1 ## partno_attach() args: the partno, start_new, and distance arguments are added above
    dummy3=
      assert(num_defined([to,child])<2, "Cannot combine deprecated 'to' argument with 'child' parameter")
      assert(num_defined([from,parent])<2, "Cannot combine deprecated 'from' argument with 'parent' parameter")
      assert(spin!="align" || is_def(align), "Can only set spin to \"align\" when the 'align' parameter is given")
      assert(is_finite(spin) || spin=="align", "Spin must be a number (unless align is given)")
      assert((is_undef(overlap) || is_finite(overlap)) && (is_def(overlap) || is_undef($overlap) || is_finite($overlap)),
             str("Provided ",is_def(overlap)?"":"$","overlap is not valid."));
    if (is_def(to))
      echo("The 'to' option to attach() is deprecated and will be removed in the future.  Use 'child' instead.");
    if (is_def(from))
      echo("The 'from' option to attach(0 is deprecated and will be removed in the future.  Use 'parent' instead");
    if (norot)
      echo("The 'norot' option to attach() is deprecated and will be removed in the future.  Use position() instead.");
    req_children($children);
    
    dummy=assert($parent_geom != undef, "No object to attach to!")
          assert(is_undef(child) || is_string(child) || (is_vector(child) && (len(child)==2 || len(child)==3)),
                 "child must be a named anchor (a string) or a 2-vector or 3-vector")
          assert(is_undef(align) || !is_string(child), "child is a named anchor.  Named anchors are not supported with align=");

    two_d = _attach_geom_2d($parent_geom);
    basegeom = $parent_geom[0]=="conoid" ? attach_geom(r=2,h=2,axis=$parent_geom[5])
             : $parent_geom[0]=="prismoid" ? attach_geom(size=[2,2,2],axis=$parent_geom[4])
             : attach_geom(size=[2,2,2]);
    childgeom = attach_geom([2,2,2]);
    child_abstract_anchor = is_vector(child) && !two_d ? _find_anchor(_make_anchor_legal(child,childgeom), childgeom) : undef;

    // ## 2 ## partno_t_offset: set an offset value based on the distance argument and the value of $t
    partno_t_offset = -1 * (distance - (distance * ($t + 0.0999)));

    // ## 3 ## overlap: conditionally modify the overlap to the offset if EXPAND_PARTS and ok_to_annotate() are 
    // both true; otherwise, leave the existing specified value of overlap alone
    overlap = ((overlap!=undef)? overlap : $overlap)
        + ((expand_parts() && !is_undef(partno))
            ? partno_t_offset
            : 0);

    parent = first_defined([parent,from]);
    anchors = is_vector(parent) || is_string(parent) ? [parent] : parent;
    align_list = is_undef(align) ? [undef]
               : is_vector(align) || is_string(align) ? [align] : align;
    dummy4 = assert(is_string(parent) || is_list(parent), "Invalid parent anchor or anchor list")
             assert(spin==0 || (!two_d || is_undef(child)), "spin is not allowed for 2d objects when 'child' is given");
    child_temp = first_defined([child,to]);
    child = two_d ? _force_anchor_2d(child_temp) : child_temp;
    dummy2=assert(align_list==[undef] || is_def(child), "Cannot use 'align' without 'child'")
           assert(!inside || is_def(child), "Cannot use 'inside' without 'child'")
           assert(inset==0 || is_def(child), "Cannot specify 'inset' without 'child'")
           assert(inset==0 || is_def(align), "Cannot specify 'inset' without 'align'")
           assert(shiftout==0 || is_def(child), "Cannot specify 'shiftout' without 'child'");
    factor = inside?-1:1;
    $attach_to = child;
    for (anch_ind = idx(anchors)) {
        dummy=assert(is_string(anchors[anch_ind]) || (is_vector(anchors[anch_ind]) && (len(anchors[anch_ind])==2 || len(anchors[anch_ind])==3)),
                     str("parent[",anch_ind,"] is ",anchors[anch_ind]," but it must be a named anchor (string) or a 2-vector or 3-vector"))
              assert(align_list==[undef] || !is_string(anchors[anch_ind]),
                     str("parent[",anch_ind,"] is a named anchor (",anchors[anch_ind],"), but named anchors are not supported with align="));
        anchor = is_string(anchors[anch_ind])? anchors[anch_ind]
               : two_d?_force_anchor_2d(anchors[anch_ind])
               : point3d(anchors[anch_ind]);
        $anchor=anchor;
        anchor_data = _find_anchor(anchor, $parent_geom);
        $edge_angle = len(anchor_data)==5 ? struct_val(anchor_data[4],"edge_angle") : undef;
        $edge_length = len(anchor_data)==5 ? struct_val(anchor_data[4],"edge_length") : undef;
        $edge_end1 = len(anchor_data)==5 ? struct_val(anchor_data[4],"vec") : undef;
        anchor_pos = anchor_data[1];
        anchor_dir = factor*anchor_data[2];
        anchor_spin = two_d || !inside || anchor==TOP || anchor==BOT ? anchor_data[3]
                    : let(spin_dir = rot(anchor_data[3],from=UP, to=-anchor_dir, p=BACK))
                      _compute_spin(anchor_dir,spin_dir);
        parent_abstract_anchor = is_vector(anchor) && !two_d ? _find_anchor(_make_anchor_legal(anchor,basegeom),basegeom) : undef;
        for(align_ind = idx(align_list)){
            align = is_undef(align_list[align_ind]) ? undef
                  : assert(is_vector(align_list[align_ind],2) || is_vector(align_list[align_ind],3), "align direction must be a 2-vector or 3-vector")
                    two_d ? _force_anchor_2d(align_list[align_ind])
                  : point3d(align_list[align_ind]);
            spin = is_num(spin) ? spin
                 : align==CENTER ? 0
                 : sum(v_abs(anchor))==1 ?   // parent anchor is a face
                   let(
                       spindir = in_list(anchor,[TOP,BOT]) ? BACK : UP,
                       proj = project_plane(point4d(anchor),[spindir,align]),
                       ang = v_theta(proj[1])-v_theta(proj[0])
                   )
                   ang
                 : // parent anchor is not a face, so must be an edge (corners not allowed)
                   let(
                        nativeback = apply(rot(to=parent_abstract_anchor[2],from=UP)
                                       *affine3d_zrot(parent_abstract_anchor[3]), BACK)
                    )
                    nativeback*align<0 ? -180:0;
            $idx = align_ind+len(align_list)*anch_ind;
            $align=align;
            goodcyl = $parent_geom[0] != "conoid" || is_undef(align) || align==CTR ? true
                    : let(
                           align=rot(from=$parent_geom[5],to=UP,p=align),
                           anchor=rot(from=$parent_geom[5],to=UP,p=anchor)
                      )
                      anchor==TOP || anchor==BOT || align==TOP || align==BOT;
            badcorner = !in_list($parent_geom[0],["conoid","spheroid"]) && !is_undef(align) && align!=CTR && sum(v_abs(anchor))==3;
            badsphere = $parent_geom[0]=="spheroid" && !is_undef(align) && align!=CTR;
            dummy=assert(is_undef(align) || all_zero(v_mul(anchor,align)),
                         str("Invalid alignment: align value (",align,") includes component parallel to parent anchor (",anchor,")"))
                  assert(goodcyl, str("Cannot use align with an anchor on a curved edge or surface of a cylinder at parent anchor (",anchor,")"))
                  assert(!badcorner, str("Cannot use align at a corner anchor (",anchor,")"))
                  assert(!badsphere, "Cannot use align on spheres.");
            // Now compute position on the parent (including alignment but not inset) where the child will be anchored
            pos = is_undef(align) ? anchor_data[1] : _find_anchor(anchor+align, $parent_geom)[1];
            $attach_anchor = list_set(anchor_data, 1, pos);      // Never used;  For user informational use?  Should this be set at all?
            // Compute adjustment to the child anchor for position purposes.  This adjustment
            // accounts for the change in the anchor needed to to alignment.
            child_adjustment = is_undef(align)? CTR
                              : two_d ? rot(to=child,from=-factor*anchor,p=align)
                              : apply(   rot(to=child_abstract_anchor[2],from=UP)
                                            * affine3d_zrot(child_abstract_anchor[3])
                                            * affine3d_yrot(inside?0:180)
                                       * affine3d_zrot(-parent_abstract_anchor[3])
                                            *  rot(from=parent_abstract_anchor[2],to=UP)
                                            * rot(v=anchor,-spin),
                                      align);
            // The $anchor_override anchor value forces an override of the *position* only for the anchor
            // used when attachable() places the child
            $anchor_override = all_zero(child_adjustment)? inside?child:undef
                             : child+child_adjustment;
            reference = two_d? BACK : UP;
            // inset_dir is the direction for insetting when alignment is in effect
            inset_dir = is_undef(align) ? CTR
                      : two_d ? rot(to=reference, from=anchor,p=align)
                      : apply(affine3d_yrot(inside?180:0)
                                * affine3d_zrot(-parent_abstract_anchor[3])
                                * rot(from=parent_abstract_anchor[2],to=UP)
                                * rot(v=anchor,-spin),
                              align); 
            spinaxis = two_d? UP : anchor_dir;
            olap = - overlap * reference - inset*inset_dir + shiftout * (inset_dir + factor*reference);

            // ## 4 ## anno_partno: establish the partno for the upcoming part. This may 
            // involve the $idx value, so we cannot do that until we reach this point.
            $_anno_partno = anno_partno_attach_partno_or_idx(partno, $idx, start_new);
            partno_str = partno();

            // ## 5 ## LIST_PARTS: conditionally emit the full partno here to the console if 
            // the LIST_PARTS global is true
            if (LIST_PARTS)
                echo(str("PART:", partno_str));

            if (norot || (approx(anchor_dir,reference) && anchor_spin==0)) 
                translate(pos) rot(v=spinaxis,a=factor*spin) translate(olap) default_tag("remove",inside) children();
            else  
                translate(pos)
                    rot(v=spinaxis,a=factor*spin)
                    rot(anchor_spin,from=reference,to=anchor_dir)
                    translate(olap)
                    default_tag("remove",inside) children();

            // ## 6 ## anchor lines: conditionally draw annotation extension lines to 
            // the specified anchor. 
            if (!isolated_part() && expand_parts() && ok_to_annotate())
                attach(anchor)
                    anno_dashed_line(partno_t_offset, anchor=TOP);
        }
    }
}


// Function&Module: expand_parts()
// Synopsis: Determines or gates the expansion of parts
// Usage: as a function:
//   bool = expand_parts();
// Usage: as a module:
//   expand_parts() [CHILDREN];
// Description:
//   When called as a function, `expand_parts()` returns a 
//   boolean `bool`. A `true` value indicating that models capale of 
//   being parted out should do so; `false` otherwise.
//   .
//   When called as a module, `expand_parts()` instructs 
//   children to expand their parts if possible.
// See Also: partno(), partno_attach(), collapse_parts()
function expand_parts() = (EXPAND_PARTS || $_EXPAND_PARTS);

module expand_parts() {
    let($_EXPAND_PARTS = true)
        children();
}


// Function&Module: collapse_parts()
// Synopsis: Determines or un-gates the expansion of parts
// Usage: as a function:
//   bool = collapse_parts();
// Usage: as a module:
//   collapse_parts() [CHILDREN];
// Description:
//   When called as a function, `collapse_parts()` returns a 
//   boolean `bool`. A `true` value indicating that models capale of 
//   being parted out should no longer do so; `false` otherwise.
//   .
//   When called as a module, `collapse_parts()` instructs 
//   children to expand their parts if possible.
// See Also: partno(), partno_attach(), expand_parts()
function collapse_parts() = !expand_parts();

module collapse_parts() {
    let(EXPAND_PARTS = false, $_EXPAND_PARTS = false)
        children();
}


// Function&Module: isolate_part()
// Synopsis: Determines or starts the isolation of a single part
// Usage: as a function:
//   bool = isolate_part();
//   bool = isolate_part(<partno=partno()>, <isolated_part=isolated_part()>);
// Usage: as a module:
//   isolate_part() [CHILDREN];
//   isolate_part(<partno=undef>) [CHILDREN];
// Description:
//   When called as a function when a part is to be isolated in the 
//   current hierarchy, returns a boolean `bool` as whether the 
//   part number is to be isolated and displayed, indicated with a `true` value; or to be ignored and not 
//   shown in-scene, indicated with a `false` value. 
//   If optionally called with a part number string `partno`,
//   that part number will be used for consideration instead of the 
//   currently active part-number gleaned from the child hirearchy.
//   The option `isolated_part` will take precedence 
//   over either globally set via `ISOLATED_PART` or previous 
//   calls of `isolate_part()`.
//   .
//   When called as a module, `isolate_part()` instructs the 
//   hirearchy to restrict producing models in-scene that do not 
//   match the value of `ISOLATED_PART`. If optionally called with a 
//   part number string `partno`, that part number will be used for consideration
//   over any set in the hirearchy. 
//   .
//   In both function and module modes, `isolate_part()` will examine 
//   an optional `partno` argument, the locally scoped `$_ISOLATED_PART`, 
//   and finally the global `ISOLATED_PART`, in that order, to make its
//   decisions.
//
// Arguments:
//   partno = An optional part-number; if specified, will take precedence over the locally scoped and global values. Default: `undef`
//   isolated_part = When used as a function, will use this as the comparison over a globally set value.
//
// Continues:
//   Generally speaking, *you need not call `isolate_part()` manually.* The isolation activity that 
//   that `isolate_part()` provides as a module happens automatically within `attachable()`, and bases
//   its decisions on the globally set `ISOLATED_PART`. Invoking `isolate_part()` at the top of a 
//   child hierarchy duplicates that effort; and, inserting an `isolate_part()` module call in the 
//   middle of a hierarchy won't ensure that models above it, or in another hirearchy, won't also 
//   be displayed (thus negating the notion of "isolation"). Use of `isolate_part()` as a module 
//   should be done sparingly, perhaps only while in testing.
//
// Example(NORENDER): simple function use:
//   ISOLATED_PART = "EX-1";
//   echo(isolate_part());
//   // yields: false
//   partno(1)
//     cuboid(10)
//       echo(isolate_part());
//   // yields: true
// 
// Example(3D): simple module use: tell a child hirearchy to isolate part `EX-1-2-3`, without the use of a globally defined variable:
//   isolate_part("EX-1-2-3")
//     partno(1)
//       recolor("red") cuboid(30)
//         partno_attach(TOP, BOTTOM, partno=2)
//           recolor("blue") cuboid(20)
//             partno_attach(TOP, BOTTOM, partno=3)
//               recolor("yellow") cuboid(10)
//                 partno_attach(TOP, BOTTOM, partno=4)
//                   recolor("green") cuboid(5);
//
// Example(3D): same example as above, but the `isolate_part()` call is inserted in the middle of the hirearchy. It still shows `EX-1-2-3`, but also all the parts that came before it:
//   partno(1)
//     recolor("red") cuboid(30)
//       partno_attach(TOP, BOTTOM, partno=2)
//         recolor("blue") cuboid(20)
//           isolate_part("EX-1-2-3")
//             partno_attach(TOP, BOTTOM, partno=3)
//               recolor("yellow") cuboid(10)
//                 partno_attach(TOP, BOTTOM, partno=4)
//                   recolor("green") cuboid(5);
//
// Example(3D): same example as above, but using the globally-set `ISOLATED_PART` variable instead. This allows you to model as normal, and selectively isolate a complex scene without inserting `isolate_part()` calls throughout your source:
//   ISOLATED_PART = "EX-1-2-3";
//   partno(1)
//     recolor("red") cuboid(30)
//       partno_attach(TOP, BOTTOM, partno=2)
//         recolor("blue") cuboid(20)
//           partno_attach(TOP, BOTTOM, partno=3)
//             recolor("yellow") cuboid(10)
//               partno_attach(TOP, BOTTOM, partno=4)
//                 recolor("green") cuboid(5);
// See Also: isolated_part(), partno_attach()
function isolate_part(partno=partno(), isolated_part=isolated_part()) = 
    assert(is_string(partno) || is_undef(partno), str("Part-number (",partno,") is not a string")) 
    assert(is_string(isolated_part) || is_undef(isolated_part), str("Highlighted part-number (",isolated_part,") is not a string")) 
    let(
        allowed = _defined(isolated_part)
            ? partno == isolated_part
            : true
    )
    allowed;

module isolate_part(partno=undef) {
    req_children($children);
    assert(is_string(partno) || is_undef(partno), str("Provided part-number '", partno, "' is not a string"))
        let($_ISOLATED_PART = isolated_part(partno))
            children();
}


// Function: isolated_part()
// Synopsis: Returns the current part number to isolate
// Usage:
//   part_str = isolated_part();
//   part_str = isolated_part(<partno=undef>);
// Description:
//   When a part is to be isolated in the 
//   current hierarchy, returns the part number `partno` as a string of the 
//   part to be isolated. If optionally called with a part number string `partno`,
//   that part number will be used for consideration. If no part is meant to be isolated, 
//   `isolated_part()` should return `undef`.
// Arguments:
//   partno = An optional part-number; if specified, will take precedence over the locally scoped and global values. Default: `undef`
// Example(NORENDER):
//   echo(isolated_part());
//   // yields: "ECHO: undef"
//   partno(1)
//     cuboid(10)
//       echo(isolated_part());
//   // yields: "EX-1"
function isolated_part(partno=undef) = _first([partno, $_ISOLATED_PART, ISOLATED_PART]);


/// Module: isolate_attachable_part()
/// Synopsis: gates parts from isolation when triggered by attachable() (via _show_ghost() override)
/// Usage:
///   [PARENT] isolate_attachable_part() [ATTACHABLE]
/// Description:
///   Gates displaying of a hirearchy when `isolated_part()` returns false. This 
///   is an internal module meant to work in conjunction with the overloaded `_show_ghost()`,
///   itself run from within `attachable()`. 
module isolate_attachable_part() {
    req_children($children);
    let($_ISOLATED_PART = isolated_part())
    if (!isolate_part()) {
        hide_this() children();
    } else {
        children();
    }
}


/// Internal Function: _show_ghost()
/// Synopsis: Overloaded version of BOSL2's _show_ghost() with isolation functionality
/// Usage:
///   [PARENT] _show_ghost() [ATTACHABLE];
/// Description:
///   Overloaded `_show_ghost()` from BOSL2's attachments.scad to add isolation gating.
///   This module differs from BOSL2's `_show_ghost()` in the following specific way: 
///   .
///   1. singular part isolation: if `ISOLATED_PART` is set to a string, attachable shapes or models
///   will not be displayed until they are preceeded with a `partno()` or `partno_attach()` module 
///   call setting that part number. Within `_show_ghost()`, an additional call is made 
///   to `isolate_attachable_part()` just before this module's children are called: the `isolate_attachable_part()`
///   module deterimes if the children should be executed for displaying or not. 
///   .
///   The changes were kept to an absolute minimum; BOSL2's `_show_ghost()` functionality is otherwise as-is, as of 
///   2025-02-13. You'll want to review the 
///   [documentation for `attach()`](https://github.com/BelfrySCAD/BOSL2/wiki/attachments.scad#module-attach) 
///   as well as [the Attachments tutorial](https://github.com/BelfrySCAD/BOSL2/wiki/Tutorial-Attachments)
///   for a full understanding of how attachments work.
/// See Also: partno_attach(), isolate_attachable_part()
module _show_ghost()
{  
    if (($ghost || $ghost_this) && !$ghosting)
        %union(){
           $ghosting=true;
           _show_highlight() isolate_attachable_part() children();
        }
    else _show_highlight() isolate_attachable_part() children();
}


/// Module: anno_dashed_line()
/// Synopsis: Models an attachable dashed line
/// Usage:
///   anno_dashed_line(length);
///   anno_dashed_line(length, <diam=0.3>, <color="black">, <alpha=0.4>, <anchor=BOTTOM>, <spin=0>, <orient=UP>);
/// Description:
///   Given a distance `length`, models an attachable dotted line.
module anno_dashed_line(length, diam=0.3, color="black", alpha=0.4, anchor=BOTTOM, spin=0, orient=UP) {
    attachable(anchor, spin, orient, l=length, d=diam) {
        down(length/2)
            color(color, alpha)
                dashed_stroke([[0, 0, 0], [0, 0, length]], [10, 3], width=diam, closed=false);
        children();
    }
}


/// Function: anno_partno_attach_partno_or_idx()
/// Synopsis: generates a suitable partno for elements within partno_attach()
/// Usage:
///   partno = anno_partno_attach_partno_or_idx(partno, idx, start_new);
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
function anno_partno_attach_partno_or_idx(partno, idx=undef, start_new=false) = 
    let(
        pn = (partno == "idx" && !is_undef(idx)) ? idx : partno,
        apno = (!_defined(pn))
            ? $_anno_partno
            : (start_new)
                ? [pn]
                : (_defined($_anno_partno)) 
                    ? concat($_anno_partno, pn) 
                    : [pn]
    )
    apno;


// Section: Displaying Annotations onto Shapes and Models
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
//   [ATTACHABLE] annotate(<description>, <show=["label", "desc"]>, <anchor=RIGHT>, <label=undef>, <partno=undef>, <spec=undef>, <obj=undef>, <leader_len=30>, <color=undef>, <alpha=undef>);
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
//   description = An optional description that only applies to this annotation text block. No default. 
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
//    obj() documentation is lacking, only because I don't feel like providing a simulated Object handler. Literally any openscad_object Object will work with `annotate()`, and 507common has the best examples; when that repo is made public, I'll crib some from there to here.
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
    anno = Annotation([
            "label",  _first([label,  label()]),
            "partno", _first([partno, partno()]),
            "spec",   _first([spec,   spec()]),
            "obj",    _first([obj,    obj()]),
            "desc",   _first([desc,   desc()]),
            "color",  color,
            "alpha",  alpha,
            "leader_len", leader_len
            ]);

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
                ? [[anno_label(anno)], anno_size_for_attr("label")] 
                : undef,
            (in_list("partno", blocks))
                ? [[anno_partno(anno)], anno_size_for_attr("partno")] 
                : undef,
            (in_list("desc", blocks))
                ? [[anno_desc(anno)], anno_size_for_attr("desc")] 
                : undef,
            (in_list("spec", blocks))
                ? [anno_list_to_block(anno_spec(anno)), anno_size_for_attr("spec")] 
                : undef,
            (in_list("obj", blocks))
                ? [anno_obj_to_block(anno_obj(anno)), anno_size_for_attr("obj")] 
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


/// Function: anno_partno_list()
/// Synopsis: Return a list of part number elements
/// Usage:
///   list = anno_partno_list();
///   list = anno_partno_list(<anno=Annotation object>, <mech_number=true>, <label=true>);
/// Description:
///   Returns a list of part number elements as `list`. 
///   If an explicit Annotation object is passed via the `anno` argument, 
///   `anno_partno_list()` will use that object instead of gleaning the 
///   current Annotation state from local- and dollar-sign-prefixed- variables. 
///
/// Arguments:
///   anno = An Annotation object. If unspecified, a new Annotation object will be instantiated for `anno_partno_list()`.
///   mech_number = If set to `true`, will include the mech number (if set) in the returned partno list. Default: `true`
///   label = If set to `true`, will include the label number (if set) in the returned partno list. Default: `true`
function anno_partno_list(anno=Annotation(), mech_number=true, label=true) =
    let(
        apl = flatten([
            (mech_number) ? anno_mech_number(anno) : undef,
            (label) ? anno_label(anno) : undef,
            flatten(anno_partno(anno))
        ])
    )
    list_remove_values(apl, undef, all=true);


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




/// Function: anno_partno_translate()
/// Synopsis: Transform an annotation part-number to a 3D point for positioning
/// Usage:
///   xyz_offset = anno_partno_translate();
///   xyz_offset = anno_partno_translate(<d=30>);
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
///   d = Value used for distancing individual steps of movement. Default: `50`
///
function anno_partno_translate(d=15, vectors=[]) =
    let(
        vec = (len(vectors) > 0)
            ? vectors
            : [for (i=anno_partno_list()) bin2vec(multi_bw_xor(str2bin(i)))]
    ) 
    assert(len(vec) > 0)
    let(
        off = vec[0] * d,
        u = off - (off * min([1, $t])),
        v = (len(vec) > 1)
            ? move(u, p=anno_partno_translate(d=d, vectors=select(vec, 1, -1)))
            : move(u, p=CENTER)
    )
    v;



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
function str2bin(s) = [for (i=s) ascii2bin(str(i))];


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
        cs = str(c)
    )
    assert(len(cs) > 0)
    dec2bin(ord(cs[0]));


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
    )
    b;

function _dec2bin_rec(d) =
    let(
        q = floor(d / 2),
        r = d - (q * 2),
        accum = (q > 0) ? _dec2bin_rec(q) : [],
        bin = list_insert(accum, len(accum), r)
    )
    bin;


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
function Annotation(vlist=[], mutate=[]) = 
    let(
        o_ = Object("Annotation", Annotation_attrs, vlist=vlist, mutate=mutate),
        vl = [
            "mech_number", obj_accessor_get(o_, "mech_number", default=((!MECH_NUMBER) ? undef : MECH_NUMBER)),
            "label",       obj_accessor_get(o_, "label",       default=$_anno_labelname),
            "partno",      obj_accessor_get(o_, "partno",      default=$_anno_partno),
        ]
    )
    Object("Annotation", Annotation_attrs, vlist=vl, mutate=o_);

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


