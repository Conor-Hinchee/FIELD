import Toybox.Graphics;
import Toybox.System;
import Toybox.Lang;
import Toybox.Math;

// BatteryDial — a beveled sub-dial below the 12 o'clock index: a segmented
// level ring, a battery glyph, and the live battery percentage.
//
// Geometry is anchored to the chapter ring: the 12 index's inner tip sits at
// (INSET + LENGTH) = 50 px in from the screen edge, and we drop GAP px below.
class BatteryDial {

    const IDX_INNER = 50;   // chapter-ring INSET(2) + LENGTH(48)
    const GAP       = 15;   // gap below the 12 index
    const DIAL_R    = 54;   // sub-dial radius
    const RIM       = 4;    // bezel thickness

    // segmented level gauge around the inner edge
    const SEG_N     = 30;   // number of segments in the ring
    const SEG_LEN   = 8;    // segment radial length
    const SEG_HW    = 2;    // segment half-width (gaps come from N vs width)
    const SEG_DOT   = 2;    // empty-segment ball radius
    const SEG_OFF   = 2;    // inset from the black face edge (hug the bezel)

    function draw(dc, cx, cy) {
        var topRadius = cx - IDX_INNER - GAP;        // center -> bezel top edge
        var subCx     = cx;
        var subCy     = cy - (topRadius - DIAL_R);   // sub-dial center

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
        drawBatteryGlyph(dc, subCx, subCy - 16, 27, 15, pct, col);

        // percentage
        dc.setColor(col, Graphics.COLOR_TRANSPARENT);
        dc.drawText(subCx, subCy + 12,
                    Fonts.vector(dc, (dc.getFontHeight(Graphics.FONT_XTINY) * 3) / 4),
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
        dc.setColor(0x505050, Graphics.COLOR_TRANSPARENT);
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
