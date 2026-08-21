import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Time;
import Toybox.Time.Gregorian;

// DateDial — a sub-dial between the 9 and 10 o'clock indices showing weekday +
// day of month. Unlike the other dials it uses a plain flat gray outline
// rather than the beveled bezel.
class DateDial {

    const POS_FRAC = 9.5 / 12.0;  // clock position (between 9 and 10)
    const POS_R    = 110;         // sub-dial center distance from dial center
    const DIAL_R   = 54;          // sub-dial radius

    function draw(dc, cx, cy) {
        var p   = Geometry.polar(cx, cy, POS_R, POS_FRAC);
        var dcx = p[0];
        var dcy = p[1];

        // black face with a plain 1.5px gray outline (no bevel)
        dc.setColor(0x000000, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(dcx, dcy, DIAL_R);
        dc.setPenWidth(1.5);
        dc.setColor(0x808080, Graphics.COLOR_TRANSPARENT);
        dc.drawCircle(dcx, dcy, DIAL_R - 2);

        // --- date ---
        var now = Gregorian.info(Time.now(), Time.FORMAT_SHORT);

        // weekday (small, up top)
        dc.setColor(Palette.SECONDARY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dcx, dcy - 15,
                    Fonts.vector(dc, (dc.getFontHeight(Graphics.FONT_XTINY) * 11) / 20),
                    dowName(now.day_of_week),
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // day of month (large, below)
        dc.setColor(Palette.PRIMARY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dcx, dcy + 9,
                    Fonts.vector(dc, (dc.getFontHeight(Graphics.FONT_XTINY) * 7) / 6),
                    now.day.toString(),
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    private function dowName(dow) {
        var names = [ "", "SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT" ];
        return names[dow];
    }
}
