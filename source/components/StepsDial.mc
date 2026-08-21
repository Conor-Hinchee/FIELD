import Toybox.Graphics;
import Toybox.Lang;
import Toybox.ActivityMonitor;

// StepsDial — a beveled sub-dial between the 4 and 5 o'clock indices (mirrors
// the heart dial) showing the live step count + distance in miles.
class StepsDial {

    const POS_FRAC = 4.5 / 12.0;  // clock position (between 4 and 5)
    const POS_R    = 110;         // sub-dial center distance from dial center
    const DIAL_R   = 40;          // sub-dial radius (mirrors the heart dial)
    const RIM      = 3;           // bezel thickness

    function draw(dc, cx, cy) {
        var p   = Geometry.polar(cx, cy, POS_R, POS_FRAC);
        var scx = p[0];
        var scy = p[1];

        SubDial.beveledFace(dc, scx, scy, DIAL_R, RIM);

        // --- steps + distance ---
        var info   = ActivityMonitor.getInfo();
        var steps  = (info != null && info.steps != null) ? info.steps : 0;
        var distCm = (info != null && info.distance != null) ? info.distance : 0;
        var miles  = distCm / 160934.4;

        // step count
        dc.setColor(Palette.PRIMARY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(scx, scy - 6,
                    Fonts.vector(dc, (dc.getFontHeight(Graphics.FONT_XTINY) * 11) / 20),
                    groupThousands(steps),
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // distance in miles
        dc.setColor(Palette.TERTIARY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(scx, scy + 12,
                    Fonts.vector(dc, dc.getFontHeight(Graphics.FONT_XTINY) / 2),
                    miles.format("%.1f") + " MI",
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
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
