import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.ActivityMonitor;

// StepsDial — a beveled sub-dial below the 12 o'clock index showing the live
// step count + distance in miles, wrapped in a segmented progress ring that
// fills clockwise from 12 toward the daily step goal.
class StepsDial {

    const IDX_INNER = 50;   // chapter-ring INSET(2) + LENGTH(48)
    const GAP       = 15;   // gap below the 12 index
    const DIAL_R    = 54;   // sub-dial radius (the big 12 o'clock slot)
    const RIM       = 4;    // bezel thickness

    // segmented step-goal progress ring around the inner edge (rhymes with the
    // battery level ring, one size up for the larger 12 o'clock dial).
    const SEG_N     = 30;   // number of segments in the ring
    const SEG_LEN   = 7;    // segment radial length
    const SEG_HW    = 1.5;  // segment half-width (gaps come from N vs width)
    const SEG_DOT   = 1.5;  // empty-segment ball radius
    const SEG_OFF   = 3;    // inset from the black face edge (hug the bezel)

    function draw(dc, cx, cy) {
        var topRadius = cx - IDX_INNER - GAP;        // center -> bezel top edge
        var scx       = cx;
        var scy       = cy - (topRadius - DIAL_R);   // sub-dial center

        SubDial.beveledFace(dc, scx, scy, DIAL_R, RIM);

        // --- steps + distance ---
        var info   = ActivityMonitor.getInfo();
        var steps  = (info != null && info.steps != null) ? info.steps : 0;
        var goal   = (info != null && info.stepGoal != null && info.stepGoal > 0)
                        ? info.stepGoal : 10000;
        var distCm = (info != null && info.distance != null) ? info.distance : 0;
        var miles  = distCm / 160934.4;

        // progress ring: bars fill clockwise from 12, each unreached slot
        // collapsing to a dim ball. Goal met -> the ring simply fills out.
        var progress = steps.toFloat() / goal;
        if (progress > 1.0) { progress = 1.0; }
        var filled = (progress * SEG_N + 0.5).toNumber();
        if (filled > SEG_N) { filled = SEG_N; }
        var ringCol = Palette.PRIMARY;
        var segOut  = DIAL_R - RIM - SEG_OFF;
        for (var s = 0; s < SEG_N; s += 1) {
            var f = s.toFloat() / SEG_N;   // 0 at top, increasing clockwise
            if (s < filled) {
                drawSegment(dc, scx, scy, f, segOut, ringCol);
            } else {
                drawEmptyBall(dc, scx, scy, f, segOut);
            }
        }

        // step count
        dc.setColor(Palette.PRIMARY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(scx, scy - 6,
                    Fonts.vector(dc, (dc.getFontHeight(Graphics.FONT_XTINY) * 11) / 15),
                    groupThousands(steps),
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // distance in miles
        dc.setColor(Palette.SECONDARY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(scx, scy + 17,
                    Fonts.vector(dc, (dc.getFontHeight(Graphics.FONT_XTINY) * 3) / 5),
                    miles.format("%.1f") + " MI",
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // A filled progress bar: a short radial rectangle just inside the bezel.
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

    // An unreached slot: a single dim ball where the bar would be.
    private function drawEmptyBall(dc, cx, cy, fraction, rOut) {
        var rMid = rOut - (SEG_LEN / 2);
        var p = Geometry.polar(cx, cy, rMid, fraction);
        dc.setColor(0x505050, Graphics.COLOR_TRANSPARENT);   // dim "off" gray
        dc.fillCircle(p[0], p[1], SEG_DOT);
    }

    private function groupThousands(n) {
        var s = n.toString();
        var out = "";
        var c = 0;
        for (var i = s.length() - 1; i >= 0; i -= 1) {
            out = s.substring(i, i + 1) + out;
            c += 1;
            if (c % 3 == 0 && i > 0) { out = "," + out; }
        }
        return out;
    }
}
