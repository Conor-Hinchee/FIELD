import Toybox.Graphics;
import Toybox.Lang;
import Toybox.ActivityMonitor;

// StepsDial — a beveled sub-dial matching the battery/weather/heart bezels,
// seated between the 4 and 5 o'clock indices (mirrors the heart dial). Shows
// a footprints glyph + live step count.
class StepsDial {

    const POS_FRAC = 4.5 / 12.0;  // clock position (between 4 and 5)
    const POS_R    = 110;         // sub-dial center distance from dial center
    const DIAL_R   = 40;          // sub-dial radius (mirrors the heart dial)
    const RIM      = 3;           // bezel thickness

    function draw(dc, cx, cy) {
        var p   = Geometry.polar(cx, cy, POS_R, POS_FRAC);
        var scx = p[0];
        var scy = p[1];

        // dark-grey bezel base
        dc.setColor(0x484848, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(scx, scy, DIAL_R);

        // beveled rim: lighter grey on top, darker on the bottom (top-lit)
        dc.setPenWidth(RIM);
        dc.setColor(0x707070, Graphics.COLOR_TRANSPARENT);
        dc.drawArc(scx, scy, DIAL_R - 2, Graphics.ARC_COUNTER_CLOCKWISE, 35, 145);
        dc.setColor(0x282828, Graphics.COLOR_TRANSPARENT);
        dc.drawArc(scx, scy, DIAL_R - 2, Graphics.ARC_COUNTER_CLOCKWISE, 215, 325);

        // black face
        dc.setColor(0x000000, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(scx, scy, DIAL_R - RIM);

        // --- steps + distance ---
        var info  = ActivityMonitor.getInfo();
        var steps = (info != null && info.steps != null) ? info.steps : 0;
        var distCm = (info != null && info.distance != null) ? info.distance : 0;
        var miles  = distCm / 160934.4;

        // step count
        dc.setColor(Palette.PRIMARY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(scx, scy - 6, vfont(dc, (dc.getFontHeight(Graphics.FONT_XTINY) * 11) / 20),
                    groupThousands(steps), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // distance in miles
        dc.setColor(Palette.TERTIARY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(scx, scy + 12, vfont(dc, dc.getFontHeight(Graphics.FONT_XTINY) / 2),
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

    private function vfont(dc, size) {
        if (Graphics has :getVectorFont) {
            var faces = ["RobotoCondensedBold", "RobotoRegular", "RobotoCondensedRegular"];
            for (var i = 0; i < faces.size(); i += 1) {
                var vf = Graphics.getVectorFont({:face => faces[i], :size => size});
                if (vf != null) { return vf; }
            }
        }
        return Graphics.FONT_XTINY;
    }
}
