import Toybox.Graphics;
import Toybox.Lang;
import Toybox.ActivityMonitor;

// StepsDial — a beveled sub-dial below the 12 o'clock index showing the live
// step count + distance in miles.
class StepsDial {

    const IDX_INNER = 50;   // chapter-ring INSET(2) + LENGTH(48)
    const GAP       = 15;   // gap below the 12 index
    const DIAL_R    = 54;   // sub-dial radius (the big 12 o'clock slot)
    const RIM       = 4;    // bezel thickness

    function draw(dc, cx, cy) {
        var topRadius = cx - IDX_INNER - GAP;        // center -> bezel top edge
        var scx       = cx;
        var scy       = cy - (topRadius - DIAL_R);   // sub-dial center

        SubDial.beveledFace(dc, scx, scy, DIAL_R, RIM);

        // --- steps + distance ---
        var info   = ActivityMonitor.getInfo();
        var steps  = (info != null && info.steps != null) ? info.steps : 0;
        var distCm = (info != null && info.distance != null) ? info.distance : 0;
        var miles  = distCm / 160934.4;

        // step count
        dc.setColor(Palette.PRIMARY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(scx, scy - 6,
                    Fonts.vector(dc, (dc.getFontHeight(Graphics.FONT_XTINY) * 11) / 15),
                    groupThousands(steps),
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // distance in miles
        dc.setColor(Palette.TERTIARY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(scx, scy + 16,
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
