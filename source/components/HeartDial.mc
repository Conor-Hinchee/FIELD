import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Activity;
import Toybox.ActivityMonitor;

// HeartDial — a beveled sub-dial matching the battery/weather bezels, seated
// between the 7 and 8 o'clock indices. Shows a heart glyph + live BPM.
class HeartDial {

    const POS_FRAC = 7.5 / 12.0;  // clock position (between 7 and 8)
    const POS_R    = 110;         // sub-dial center distance from dial center
    const DIAL_R   = 40;          // sub-dial radius (25% smaller)
    const RIM      = 3;           // bezel thickness

    function draw(dc, cx, cy) {
        var p   = Geometry.polar(cx, cy, POS_R, POS_FRAC);
        var hcx = p[0];
        var hcy = p[1];

        // dark-grey bezel base
        dc.setColor(0x484848, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(hcx, hcy, DIAL_R);

        // beveled rim: lighter grey on top, darker on the bottom (top-lit)
        dc.setPenWidth(RIM);
        dc.setColor(0x707070, Graphics.COLOR_TRANSPARENT);
        dc.drawArc(hcx, hcy, DIAL_R - 2, Graphics.ARC_COUNTER_CLOCKWISE, 35, 145);
        dc.setColor(0x282828, Graphics.COLOR_TRANSPARENT);
        dc.drawArc(hcx, hcy, DIAL_R - 2, Graphics.ARC_COUNTER_CLOCKWISE, 215, 325);

        // black face
        dc.setColor(0x000000, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(hcx, hcy, DIAL_R - RIM);

        // --- heart rate ---
        var hr    = currentHeartRate();
        var hrStr = (hr != null) ? hr.toString() : "--";

        // red heart glyph that pulses once per second (active mode only —
        // a watch face can't redraw fast enough for a true heartbeat)
        var pulse = ((System.getClockTime().sec % 3) == 0) ? 12.5 : 12.0;
        drawHeart(dc, hcx, hcy - 14, pulse, Palette.ACCENT);

        // BPM number (near center)
        dc.setColor(Palette.PRIMARY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(hcx, hcy + 4, vfont(dc, (dc.getFontHeight(Graphics.FONT_XTINY) * 11) / 20),
                    hrStr, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // BPM label
        dc.setColor(Palette.TERTIARY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(hcx, hcy + 19, vfont(dc, (dc.getFontHeight(Graphics.FONT_XTINY) * 3) / 8),
                    "BPM", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // Two raised lobes + a tapered tail, built from convex pieces so it fills
    // solid and scales cleanly (a concave one-polygon heart triangulates and
    // shimmers when it pulses).
    private function drawHeart(dc, cx, cy, s, color) {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        var lobe = s * 0.31;
        var ly   = cy - s * 0.14;
        dc.fillCircle(cx - s * 0.28, ly, lobe);
        dc.fillCircle(cx + s * 0.28, ly, lobe);
        dc.fillPolygon([
            [ cx - s * 0.58, cy - s * 0.11 ],
            [ cx + s * 0.58, cy - s * 0.11 ],
            [ cx,            cy + s * 0.85 ]
        ]);
    }

    private function currentHeartRate() {
        // Guarded: HR access can throw in a watch-face context on some
        // devices; degrade to "--" rather than taking down the whole face.
        try {
            var act = Activity.getActivityInfo();
            if (act != null && act.currentHeartRate != null) {
                return act.currentHeartRate;
            }
            var iter = ActivityMonitor.getHeartRateHistory(1, true);
            if (iter != null) {
                var s = iter.next();
                if (s != null && s.heartRate != null
                        && s.heartRate != ActivityMonitor.INVALID_HR_SAMPLE) {
                    return s.heartRate;
                }
            }
        } catch (ex) {
            return null;
        }
        return null;
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
