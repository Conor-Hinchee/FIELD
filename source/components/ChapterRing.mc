import Toybox.Graphics;
import Toybox.Math;

// ChapterRing — the outer ring of the dial: the minute track plus the applied
// hour indices (the beveled silver batons). 12 o'clock is a double index.
//
// Tunables live at the top: change these to reshape the ring.
class ChapterRing {

    const INSET     = 2;        // gap from the screen edge
    const HALF_W    = 5;        // index half-width
    const LENGTH    = 48;       // index length (radial)
    const TICK_IN   = 10;       // minute-tick length
    const TICK_COL  = 0x8A8A8A; // minute-track gray

    function draw(dc, cx, cy) {
        var rOut = cx - INSET;

        // minute track: crisp mid-gray, subordinate to the indices
        dc.setColor(TICK_COL, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        for (var i = 0; i < 60; i += 1) {
            if ((i % 5) == 0) { continue; }
            var f  = i / 60.0;
            var p1 = Geometry.polar(cx, cy, rOut, f);
            var p2 = Geometry.polar(cx, cy, rOut - TICK_IN, f);
            dc.drawLine(p1[0], p1[1], p2[0], p2[1]);
        }

        // hour indices
        for (var h = 0; h < 12; h += 1) {
            if (h == 0) {
                // 12 o'clock: two beveled bars flush against each other
                drawIndex(dc, cx, cy, 0.0, rOut, rOut - LENGTH, HALF_W, -HALF_W);
                drawIndex(dc, cx, cy, 0.0, rOut, rOut - LENGTH, HALF_W,  HALF_W);
            } else {
                drawIndex(dc, cx, cy, h / 12.0, rOut, rOut - LENGTH, HALF_W, 0);
            }
        }
    }

    // Beveled index, three layers so it reads as raised brushed metal:
    //   dark rim (largest) -> silver face -> bright specular core (inset).
    // `off` shifts the index along the tangent (perpendicular to its radius).
    private function drawIndex(dc, cx, cy, fraction, rOuter, rInner, hw, off) {
        fillIndex(dc, cx, cy, fraction, rOuter + 2, rInner - 2, hw + 2,     off, Palette.HOUR_EDGE);
        fillIndex(dc, cx, cy, fraction, rOuter,     rInner,     hw,         off, Palette.HOUR);
        fillIndex(dc, cx, cy, fraction, rOuter - 2, rInner + 2, hw * 0.5,   off, Palette.HOUR_HI);
    }

    private function fillIndex(dc, cx, cy, fraction, rOuter, rInner, hw, off, color) {
        var a  = (fraction * 2.0 * Math.PI) - (Math.PI / 2.0);
        var ca = Math.cos(a);
        var sa = Math.sin(a);
        var px = -sa;  // tangent (perpendicular) direction
        var py =  ca;
        var ox = cx + rOuter * ca + off * px, oy = cy + rOuter * sa + off * py;
        var ix = cx + rInner * ca + off * px, iy = cy + rInner * sa + off * py;
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon([
            [ ox + px * hw, oy + py * hw ],
            [ ox - px * hw, oy - py * hw ],
            [ ix - px * hw, iy - py * hw ],
            [ ix + px * hw, iy + py * hw ]
        ]);
    }
}
