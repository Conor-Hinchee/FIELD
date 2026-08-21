import Toybox.Graphics;

// Shared sub-dial chrome: a dark-grey, top-lit beveled bezel around a black
// face, so the battery / weather / heart / steps dials read as one family.
// `r` is the outer radius, `rim` the bezel thickness.
module SubDial {
    function beveledFace(dc, cx, cy, r, rim) {
        // dark-grey bezel base
        dc.setColor(0x484848, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx, cy, r);

        // beveled rim: lighter grey on top, darker on the bottom (top-lit)
        dc.setPenWidth(rim);
        dc.setColor(0x707070, Graphics.COLOR_TRANSPARENT);
        dc.drawArc(cx, cy, r - 2, Graphics.ARC_COUNTER_CLOCKWISE, 35, 145);
        dc.setColor(0x282828, Graphics.COLOR_TRANSPARENT);
        dc.drawArc(cx, cy, r - 2, Graphics.ARC_COUNTER_CLOCKWISE, 215, 325);

        // black face
        dc.setColor(0x000000, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx, cy, r - rim);
    }
}
