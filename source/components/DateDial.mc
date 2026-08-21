import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Time;
import Toybox.Time.Gregorian;

// DateDial — a beveled sub-dial between the 9 and 10 o'clock indices showing
// the date stacked three tight lines: FRI / 21 / AUG. The labels share one
// width and sit ~2 px above/below the day number.
class DateDial {

    const POS_FRAC = 9.5 / 12.0;  // clock position (between 9 and 10)
    const POS_R    = 110;         // sub-dial center distance from dial center
    const DIAL_R   = 54;          // sub-dial radius
    const RIM      = 4;           // bezel thickness
    const GAP      = 2;           // vertical space between the lines

    function draw(dc, cx, cy) {
        var p   = Geometry.polar(cx, cy, POS_R, POS_FRAC);
        var dcx = p[0];
        var dcy = p[1];

        SubDial.beveledFace(dc, dcx, dcy, DIAL_R, RIM);

        var now    = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var center = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;
        var dow    = dowName(now.day_of_week);
        var mon    = monName(now.month);

        // day number (middle) sets the reference width
        var numF = Fonts.vector(dc, (dc.getFontHeight(Graphics.FONT_XTINY) * 7) / 6);
        var numH = dc.getFontHeight(numF);

        // labels share one width, scaled down a bit from the number
        var labelW = (dc.getTextWidthInPixels("28", numF) * 82) / 100;
        var fF = fitToWidth(dc, dow, labelW);
        var fA = fitToWidth(dc, mon, labelW);
        var hF = dc.getFontHeight(fF);
        var hA = dc.getFontHeight(fA);

        // nudge the whole stack down so FRI clears the top of the circle
        var midY = dcy + 4;
        var friY = midY - (numH / 2) - GAP - (hF / 2);
        var augY = midY + (numH / 2) + GAP + (hA / 2);

        dc.setColor(Palette.PRIMARY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dcx, friY, fF, dow, center);
        dc.drawText(dcx, midY, numF, now.day.toString(), center);
        dc.drawText(dcx, augY, fA, mon, center);
    }

    // a vector font sized so `text` renders about `targetW` px wide
    private function fitToWidth(dc, text, targetW) {
        var base = 30;
        var f = Fonts.vector(dc, base);
        var w = dc.getTextWidthInPixels(text, f);
        if (w <= 0) { return f; }
        return Fonts.vector(dc, (base * targetW) / w);
    }

    private function dowName(dow) {
        var names = [ "", "SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT" ];
        return names[dow];
    }

    private function monName(m) {
        var names = [ "", "JAN", "FEB", "MAR", "APR", "MAY", "JUN",
                      "JUL", "AUG", "SEP", "OCT", "NOV", "DEC" ];
        return names[m];
    }
}
