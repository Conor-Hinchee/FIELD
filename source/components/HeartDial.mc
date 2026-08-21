import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Activity;
import Toybox.ActivityMonitor;

// HeartDial — a beveled sub-dial between the 7 and 8 o'clock indices showing a
// red heart glyph (with a subtle once-per-second pulse) + live BPM.
class HeartDial {

    const POS_FRAC = 7.5 / 12.0;  // clock position (between 7 and 8)
    const POS_R    = 110;         // sub-dial center distance from dial center
    const DIAL_R   = 40;          // sub-dial radius
    const RIM      = 3;           // bezel thickness

    function draw(dc, cx, cy) {
        var p   = Geometry.polar(cx, cy, POS_R, POS_FRAC);
        var hcx = p[0];
        var hcy = p[1];

        SubDial.beveledFace(dc, hcx, hcy, DIAL_R, RIM);

        // --- heart rate ---
        var hr    = currentHeartRate();
        var hrStr = (hr != null) ? hr.toString() : "--";

        // red heart glyph, subtle pulse every 3rd second (active mode only —
        // a watch face can't redraw fast enough for a true heartbeat)
        var pulse = ((System.getClockTime().sec % 3) == 0) ? 12.5 : 12.0;
        drawHeart(dc, hcx, hcy - 14, pulse, Palette.ACCENT);

        // BPM number
        dc.setColor(Palette.PRIMARY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(hcx, hcy + 4,
                    Fonts.vector(dc, (dc.getFontHeight(Graphics.FONT_XTINY) * 11) / 20),
                    hrStr, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // BPM label
        dc.setColor(Palette.TERTIARY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(hcx, hcy + 19,
                    Fonts.vector(dc, (dc.getFontHeight(Graphics.FONT_XTINY) * 3) / 8),
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

    // Guarded: HR access can throw in a watch-face context on some devices;
    // degrade to "--" rather than taking down the whole face.
    private function currentHeartRate() {
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
}
