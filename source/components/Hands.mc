import Toybox.Graphics;
import Toybox.Math;
import Toybox.Time;
import Toybox.Time.Gregorian;

// Hands — slim, solid-white pointed blades (no bevel), plus a long slim
// seconds sweep. The center pivot belongs to CannonPinion, drawn afterward.
class Hands {

    function draw(dc, cx, cy, lowPower) {
        var now   = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var hourF = ((now.hour % 12) + (now.min / 60.0)) / 12.0;
        var minF  = now.min / 60.0;   // snap to each minute (no per-second creep)
        var secF  = now.sec / 60.0;

        // hour + minute: slim solid-white blades, continuous taper to a point
        drawBlade(dc, cx, cy, hourF, 118, 5.0);
        drawBlade(dc, cx, cy, minF,  166, 4.5);

        // seconds: long slim sweep, no backside tail (hidden in low power)
        if (!lowPower) {
            var tip  = Geometry.polar(cx, cy, 162, secF);
            var tail = Geometry.polar(cx, cy, -14, secF);   // stays under pinion
            dc.setColor(Palette.HOUR_HI, Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(2);
            dc.drawLine(tail[0], tail[1], tip[0], tip[1]);
        }
    }

    // one solid-white blade: a continuous taper from the center to the point
    private function drawBlade(dc, cx, cy, fraction, L, hw) {
        var a  = (fraction * 2.0 * Math.PI) - (Math.PI / 2.0);
        var ca = Math.cos(a);
        var sa = Math.sin(a);
        var px = -sa;
        var py =  ca;
        dc.setColor(Palette.HOUR_HI, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon([
            [ cx + hw * px, cy + hw * py ],   // base (center)
            [ cx + L * ca,  cy + L * sa ],    // point
            [ cx - hw * px, cy - hw * py ]
        ]);
    }
}
