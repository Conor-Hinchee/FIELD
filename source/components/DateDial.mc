import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Time;
import Toybox.Time.Gregorian;

// DateDial — a beveled sub-dial between the 9 and 10 o'clock indices showing
// the date stacked three lines: FRI / 21 / AUG. The weekday and month letters
// are tracked (letter-spaced) so each word spans exactly the width of the day
// number — the left and right edges line up with the "21".
class DateDial {

    const POS_FRAC = 9.5 / 12.0;  // clock position (between 9 and 10)
    const POS_R    = 110;         // sub-dial center distance from dial center
    const DIAL_R   = 54;          // sub-dial radius
    const RIM      = 4;           // bezel thickness
    const GAP      = -2;          // vertical space between the lines (tight)
    const LTR_PCT  = 88;          // label letter size as % of the number width

    function draw(dc, cx, cy) {
        var p   = Geometry.polar(cx, cy, POS_R, POS_FRAC);
        var dcx = p[0];
        var dcy = p[1];

        SubDial.beveledFace(dc, dcx, dcy, DIAL_R, RIM);

        var now    = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var dow    = dowName(now.day_of_week);
        var mon    = monName(now.month);
        var dayStr = now.day.toString();

        var numF    = Fonts.vector(dc, (dc.getFontHeight(Graphics.FONT_XTINY) * 7) / 6);
        var numH    = dc.getFontHeight(numF);
        // Span a fixed TWO-DIGIT reference width, not the actual day string —
        // otherwise single-digit days (the 1st–9th) shrink the labels to a
        // sliver. The day number is centered inside that constant column.
        var targetW = dc.getTextWidthInPixels("28", numF);
        var leftX   = dcx - (targetW / 2);                     // shared left edge

        // one letter size for all labels, then tracked to span the number width
        var lf = Fonts.vector(dc, letterSize(dc, targetW));
        var hL = dc.getFontHeight(lf);

        var friY = dcy - (numH / 2) - GAP - (hL / 2);
        var augY = dcy + (numH / 2) + GAP + (hL / 2);

        dc.setColor(Palette.PRIMARY, Graphics.COLOR_TRANSPARENT);
        drawTracked(dc, dow, leftX, friY, targetW, lf);
        dc.drawText(dcx, dcy, numF, dayStr,
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        drawTracked(dc, mon, leftX, augY, targetW, lf);
    }

    // a font size (px) for a 3-letter label, based on the widest case so every
    // day/month renders at the same letter height
    private function letterSize(dc, targetW) {
        var base = 30;
        var f = Fonts.vector(dc, base);
        var w = dc.getTextWidthInPixels("WWW", f);
        if (w <= 0) { return base; }
        return (base * ((targetW * LTR_PCT) / 100)) / w;
    }

    // draw `text` left-to-right, letter-spaced so it spans exactly targetW
    private function drawTracked(dc, text, leftX, y, targetW, font) {
        var vc = Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER;
        var n  = text.length();
        if (n <= 1) {
            dc.drawText(leftX, y, font, text, vc);
            return;
        }
        var sum = 0;
        var i;
        for (i = 0; i < n; i += 1) {
            sum += dc.getTextWidthInPixels(text.substring(i, i + 1), font);
        }
        var gap = (targetW - sum) / (n - 1).toFloat();
        var x = leftX;
        for (i = 0; i < n; i += 1) {
            var ch = text.substring(i, i + 1);
            dc.drawText(x, y, font, ch, vc);
            x += dc.getTextWidthInPixels(ch, font) + gap;
        }
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
