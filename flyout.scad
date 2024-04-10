
// Module: flyout()
// Usage:
//   flyout();
//   flyout() [CHILDREN];
//   flyout(<leader=5>, <angle=45>, <thickness=0.5>, <text=undef>, <color="black">, <alpha=0.5>, <leg1=undef>, <leg2=undef>, <anchor=CENTER>, <spin=0>, <orient=UP>);
//
// Description:
//   Creates a flyout line from one attachable point to another. Flyouts have two line leg segments angled between them, and 
//   provide two named anchors for positioning between model elements, suitable for calling attention to model aspects. 
//   .
//   The leg lengths are directed by the `leader` argument; if `leg1` or `leg2` are specified, they will be applied instead to 
//   the two leg lengths. The angle of the first lag from 0 on the Z-axis is directed by `angle`, which may be any positive value. 
//   .
//   The flyout and all subsequent children (attached or not) to the flyout will be colored with the `color` argument. 
//   If you need finer control on the colorization of the flyout and its attachments, you can do something like:
//   ```
//   recolor("black") 
//      flyout(leader=20, color=undef) 
//         attach("flyout-text", LEFT) 
//            recolor("red") 
//               attachable_text3d("A!");
//   ```
//   .
//   `flyout()` honors the result of `anno_ok_to_annotate()`, and will not render if that function does not 
//   return `true`.
//
// Arguments:
//   leader = The length of each part of flyout lines. Default: `5`
//   angle = The angle of direction change of the flyout, from the Z-axis. Default: `45`
//   thickness = The thickness of the leader lines used in the flyout. Default: `0.5`
//   text = A string of text to be positioned at the flyout's ending. Default: `undef` (for no text)
//   color = A string naming the color to render the flyout and children attached to the flyout (*including* the value of `text`, if present). Default: `black`
//   alpha = Sets the alpha transparancy of the flyout and children attached to the flyout. Default: `0.5`
//   leg1 = Set the length of the leg between the flyout's point and the flyout's angle. Default: the value of `leader`
//   leg2 = Set the length of the leg between the flyout's angle and the flyout's text point. Default: the value of `leader`
//   anchor = Translate so anchor point is at origin `[0,0,0]`. Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchoring. Default: `0`
//   orient = Vector direction to which the model should point after spin. Default: `UP`
//
// Continues:
//   It is an error to specify an `angle` value that is less than zero. It's not an error to specify an `angle` value 
//   of `0`, but know that it will be implicitly adjusted to `0.01`, because `flyout()` uses some pretty basic 
//   geometery to draw its flyout lines. It's not an error to specify an `angle` value in excess of 360, though
//   the resulting flyout may not be what you expect.
//
// Named Anchors:
//   flyout-point = The start, pointy-end of the flyout, where the arrow is, oriented downwards.
//   flyout-text = The end, text-end of the flyout, where descriptive text is placed, oriented rightwards.
// Figure: Available named anchors:
//   expose_anchors() flyout(leader=20, thickness=2, color=undef) show_anchors(std=false);
//
// Example: a basic flyout:
//   flyout();
//
// Example: a basic flyout with a simple line of text:
//   flyout(text="Some text");
//
// Example: attaching the flyout to a specific object; and, attaching some text to the flyout:
//   sphere(d=20)
//     attach(TOP+RIGHT, "flyout-point", norot=true)
//        flyout()
//           attach("flyout-text", LEFT)
//              attachable_text3d("Sphere", size=5);
//
// Example: leg & angle adjustment: `flyout()` will permit differing lengths of each leg, and of the angle:
//   flyout(text="a", angle=30, leg1=10, leg2=3);
//
// See Also: anno_ok_to_annotate()
//
module flyout(leader=10, thickness=0.5, text=undef, color="black", alpha=0.5, leg1=undef, leg2=undef, anchor=CENTER, spin=0, orient=UP) {
    if (anno_ok_to_annotate()) {
        // build up the adj/opp of a right triangle using the two legs' dimensions:
        leg1_ = _first([leg1, leader]);
        leg2_ = _first([leg2, leader]);
        assert(leg1_ >= 0);
        assert(leg2_ >= 0);

        // build a path of both legs from CENTER, to the upper angle, to the end of the second leg:
        p = [ 
            [0, 0, 0], 
            [leg1_, 0, leg1_], 
            [leg1_ + leg2_, 0, leg1_] 
            ];

        // size a cuboid the full size of the legs in x and z axis and the thickness in y:
        size = [ 
            (leg1_ + leg2_) * 2,
            thickness, 
            leg1_ * 2
            ];

        anchors = [
            named_anchor("flyout-point-angled", CENTER, -[leg1_, 0, leg1_], 0),
            named_anchor("flyout-point", CENTER, DOWN, 0),
            named_anchor("flyout-text",         
                apply(right(size.x/2) * up(size.z/2), CENTER), 
                RIGHT,
                180)
            ];

        color(_defined(color) ? color : undef, alpha=_defined(color) ? alpha : undef)
            attachable(anchor, spin, orient, size=size, anchors=anchors) {
                union() {
                    stroke(p, width=thickness, endcap1="arrow2",  endcap2="round", endcap_width1=2, endcap_length1=2*3);
                    if (_defined(text))
                        translate(p[2])
                            attachable_text3d(text, anchor=LEFT, orient=FWD);
                }
                children();
            }
    }
}


// Module: flyout_to_pos()
// Usage:
//   flyout_to_pos(pos);
//   flyout_to_pos(pos) [CHILDREN];
//   flyout(pos, <leader=5>, <angle=45>, <thickness=0.5>, <text=undef>, <color="black">, <alpha=0.5>, <leg1=undef>, <leg2=undef>);
//
// Description:
//   Creates a flyout line from one attachable point to another, and moves that flyout so that its point is at the absolute position `pos`. 
//   Flyouts have two line leg segments angled between them, and provide two named anchors for positioning between 
//   model elements, suitable for calling attention to model aspects. 
//   .
//   The leg lengths are directed by the `leader` argument; if `leg1` or `leg2` are specified, they will be applied instead to 
//   the two leg lengths. The angle of the first lag from 0 on the Z-axis is directed by `angle`, which may be any positive value. 
//   .
//   The flyout and all subsequent children (attached or not) to the flyout will be colored with the `color` argument. 
//   If you need finer control on the colorization of the flyout and its attachments, you can do something like:
//   ```
//   recolor("black") 
//      flyout([10,10,10], leader=20, color=undef) 
//         attach("flyout-text", LEFT) 
//            recolor("red") 
//               attachable_text3d("A!");
//   ```
//   .
//   `flyout_to_pos()` honors the result of `anno_ok_to_annotate()`, and will not render if that function does not 
//   return `true`.
//
//
// Arguments:
//   pos = The absolute `[x,y,z]` position at which the flyout's point is to be. No default
//   ---
//   leader = The length of each part of flyout lines. Default: `5`
//   angle = The angle of direction change of the flyout, from the Z-axis. Default: `45`
//   thickness = The thickness of the leader lines used in the flyout. Default: `0.5`
//   text = A string of text to be positioned at the flyout's ending. Default: `undef` (for no text)
//   color = A string naming the color to render the flyout and children attached to the flyout (*including* the value of `text`, if present). Default: `black`
//   alpha = Sets the alpha transparancy of the flyout and children attached to the flyout. Default: `0.5`
//   leg1 = Set the length of the leg between the flyout's point and the flyout's angle. Default: the value of `leader`
//   leg2 = Set the length of the leg between the flyout's angle and the flyout's text point. Default: the value of `leader`
//   spin = Rotate this many degrees around the Z axis after anchoring. Default: `0`
//
// Continues:
//   It is an error to specify an `angle` value that is less than zero. It's not an error to specify an `angle` value 
//   of `0`, but know that it will be implicitly adjusted to `0.01`, because `flyout()` uses some pretty basic 
//   geometery to draw its flyout lines. It's not an error to specify an `angle` value in excess of 360, though
//   the resulting flyout may not be what you expect.
//   .
//   It is an error to not specify a `pos` position to `flyout_to_pos()`, and if `pos` is undefined an error will be logged and 
//   `[0,0,0]` will be used in its place. 
//
// Example: a basic flyout, manually positioned at `[10,0,0]`:
//   flyout_to_pos([10, 0, 0]);
//
// Example: a basic flyout, manually positioned at `[10,0,0]`, with a block of text attached:
//   flyout_to_pos([10, 0, 0])
//      attach("flyout-text", LEFT)
//         attachable_text3d("Point", size=5);
//
module flyout_to_pos(pos, leader=5, thickness=0.5, text=undef, color="black", alpha=0.5, leg1=undef, leg2=undef, spin=undef) {
    pos_ = (_defined(pos))
        ? pos
        : log_error_assign([0, 0, 0], "flyout_to_pos(): No position 'pos' argument available; defaulting to");

    translate(pos_) 
        sphere(r=0.00001)
            attach(CENTER, "flyout-point")
                flyout(leader=leader, 
                        thickness=thickness, leg1=leg1, leg2=leg2,
                        text=text, color=color, alpha=alpha, 
                        spin=spin)
                    children();
}


function anno_ok_to_annotate() = true;

