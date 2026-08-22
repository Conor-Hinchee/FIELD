import Toybox.Graphics;
import Toybox.System;
import Toybox.Lang;
import Toybox.Math;

// BatteryDial — a beveled sub-dial between the 4 and 5 o'clock indices: a
// segmented level ring, a battery glyph, and the live battery percentage.
class BatteryDial {

    const POS_FRAC  = 4.5 / 12.0;  // clock position (between 4 and 5)
    const POS_R     = 110;         // sub-dial center distance from dial center
    const DIAL_R    = 40;          // sub-dial radius (the small 4-5 slot)
    const RIM       = 3;           // bezel thickness

    // segmented level gauge around the inner edge
    const SEG_N     = 24;    // number of segments in the ring
    const SEG_LEN   = 6;     // segment radial length
    const SEG_HW    = 1.5;   // segment half-width (gaps come from N vs width)
    const SEG_DOT   = 1.5;   // empty-segment ball radius
    const SEG_OFF   = 2;     // inset from the black face edge (hug the bezel)

    function draw(dc, cx, cy) {
        var p     = Geometry.polar(cx, cy, POS_R, POS_FRAC);
        var subCx = p[0];
        var subCy = p[1];

        SubDial.beveledFace(dc, subCx, subCy, DIAL_R, RIM);

        // live battery reading
        var pct = System.getSystemStats().battery.toNumber();
        var col = (pct <= 15) ? Palette.ACCENT : Palette.PRIMARY;

        // segmented level ring: filled bars for charge remaining, each spent
        // segment collapsing to a small ball. Full = a complete ring of bars.
        var segOut = DIAL_R - RIM - SEG_OFF;
        var filled = ((pct * SEG_N) / 100.0 + 0.5).toNumber();
        if (filled > SEG_N) { filled = SEG_N; }
        for (var s = 0; s < SEG_N; s += 1) {
            var f = (SEG_N - s).toFloat() / SEG_N;   // 0 at top, counter-clockwise
            if (s < filled) {
                drawSegment(dc, subCx, subCy, f, segOut, col);
            } else {
                drawEmptyBall(dc, subCx, subCy, f, segOut);
            }
        }

        // battery glyph above the number
        drawBatteryGlyph(dc, subCx, subCy - 10, 18, 10, pct, col);

        // percentage
        dc.setColor(col, Graphics.COLOR_TRANSPARENT);
        dc.drawText(subCx, subCy + 8,
                    Fonts.vector(dc, (dc.getFontHeight(Graphics.FONT_XTINY) * 11) / 20),
                    pct.toString() + "%",
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // A filled level bar: a short radial rectangle just inside the bezel.
    private function drawSegment(dc, cx, cy, fraction, rOut, color) {
        var a  = (fraction * 2.0 * Math.PI) - (Math.PI / 2.0);
        var ca = Math.cos(a);
        var sa = Math.sin(a);
        var px = -sa;
        var py =  ca;
        var ox = cx + rOut * ca,             oy = cy + rOut * sa;
        var ix = cx + (rOut - SEG_LEN) * ca, iy = cy + (rOut - SEG_LEN) * sa;
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon([
            [ ox + px * SEG_HW, oy + py * SEG_HW ],
            [ ox - px * SEG_HW, oy - py * SEG_HW ],
            [ ix - px * SEG_HW, iy - py * SEG_HW ],
            [ ix + px * SEG_HW, iy + py * SEG_HW ]
        ]);
    }

    // A spent segment: a single dim ball where the bar used to be.
    private function drawEmptyBall(dc, cx, cy, fraction, rOut) {
        var rMid = rOut - (SEG_LEN / 2);
        var p = Geometry.polar(cx, cy, rMid, fraction);
        dc.setColor(0x505050, Graphics.COLOR_TRANSPARENT);   // dim "off" gray
        dc.fillCircle(p[0], p[1], SEG_DOT);
    }

    // A small battery glyph: outline body + terminal nub, filled proportional
    // to the charge level so the icon itself reads as full / low.
    private function drawBatteryGlyph(dc, cx, cy, w, h, pct, color) {
        var x = cx - w / 2;
        var y = cy - h / 2;
        var nubH = h / 3;
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawRectangle(x, y, w, h);                            // body outline
        dc.fillRectangle(x + w, y + (h - nubH) / 2, 3, nubH);    // + terminal nub
        var fw = ((w - 4) * pct / 100.0).toNumber();            // proportional fill
        if (fw > 0) { dc.fillRectangle(x + 2, y + 2, fw, h - 4); }
    }
}
