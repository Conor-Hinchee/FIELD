import Toybox.Graphics;
import Toybox.Math;
import Toybox.Time;
import Toybox.Time.Gregorian;

// Hands — the hour, minute, and seconds hands. Hour and minute are broad
// skeletonized chrome blades (dark outline -> silver body -> bright ridge, with
// a black slot near the base); the hour tip is blunt, the minute tip is a
// pointed spear. The seconds hand is a thin bright sweep with a counterweight.
//
// The center pivot itself belongs to CannonPinion, which is drawn afterward.
class Hands {

    function draw(dc, cx, cy, lowPower) {
        var now   = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var hourF = ((now.hour % 12) + (now.min / 60.0)) / 12.0;
        var minF  = (now.min + (now.sec / 60.0)) / 60.0;
        var secF  = now.sec / 60.0;

        // hour: shorter blade, blunt squared tip (tipLen 0)
        drawBlade(dc, cx, cy, hourF, 100, 8, 24, 0);
        // minute: longer blade, pointed spear tip
        drawBlade(dc, cx, cy, minF,  150, 7, 26, 26);

        // seconds: thin bright sweep with a counterweight (skip in sleep)
        if (!lowPower) {
            var tip  = Geometry.polar(cx, cy, 158, secF);
            var tail = Geometry.polar(cx, cy, -38, secF);
            dc.setColor(Palette.HOUR_HI, Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(2);
            dc.drawLine(tail[0], tail[1], tip[0], tip[1]);
            var cw = Geometry.polar(cx, cy, -28, secF);
            dc.fillCircle(cw[0], cw[1], 4);
        }
    }

    // A broad chrome blade: dark outline -> silver body -> bright center ridge,
    // with a black skeleton slot near the base. tipLen 0 = blunt, >0 = pointed.
    private function drawBlade(dc, cx, cy, fraction, L, hw, tailLen, tipLen) {
        var a  = (fraction * 2.0 * Math.PI) - (Math.PI / 2.0);
        var ca = Math.cos(a);
        var sa = Math.sin(a);
        var px = -sa;
        var py =  ca;

        fillBlade(dc, cx, cy, ca, sa, px, py, hw + 2, L + 2, tailLen + 1, tipLen, Palette.HOUR_EDGE);
        fillBlade(dc, cx, cy, ca, sa, px, py, hw,     L,     tailLen,     tipLen, Palette.HOUR);
        // bright raised ridge down the center (blunt, stops short of the tip)
        fillBlade(dc, cx, cy, ca, sa, px, py, hw * 0.34, L - 6, tailLen - 4, 0, Palette.HOUR_HI);
        // black skeleton slot near the base
        fillSlot(dc, cx, cy, ca, sa, px, py, -tailLen + 6, L * 0.32, hw * 0.44, Palette.BG);
    }

    private function fillBlade(dc, cx, cy, ca, sa, px, py, hw, L, tailLen, tipLen, color) {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        if (tipLen > 0) {
            dc.fillPolygon([
                [ cx - tailLen * ca + hw * px, cy - tailLen * sa + hw * py ],
                [ cx + (L - tipLen) * ca + hw * px, cy + (L - tipLen) * sa + hw * py ],
                [ cx + L * ca, cy + L * sa ],
                [ cx + (L - tipLen) * ca - hw * px, cy + (L - tipLen) * sa - hw * py ],
                [ cx - tailLen * ca - hw * px, cy - tailLen * sa - hw * py ]
            ]);
        } else {
            dc.fillPolygon([
                [ cx - tailLen * ca + hw * px, cy - tailLen * sa + hw * py ],
                [ cx + L * ca + hw * px, cy + L * sa + hw * py ],
                [ cx + L * ca - hw * px, cy + L * sa - hw * py ],
                [ cx - tailLen * ca - hw * px, cy - tailLen * sa - hw * py ]
            ]);
        }
    }

    private function fillSlot(dc, cx, cy, ca, sa, px, py, u0, u1, hs, color) {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon([
            [ cx + u0 * ca + hs * px, cy + u0 * sa + hs * py ],
            [ cx + u1 * ca + hs * px, cy + u1 * sa + hs * py ],
            [ cx + u1 * ca - hs * px, cy + u1 * sa - hs * py ],
            [ cx + u0 * ca - hs * px, cy + u0 * sa - hs * py ]
        ]);
        dc.fillCircle(cx + u0 * ca, cy + u0 * sa, hs);
        dc.fillCircle(cx + u1 * ca, cy + u1 * sa, hs);
    }
}
