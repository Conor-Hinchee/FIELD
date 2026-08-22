import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.Weather;

// WeatherDial — a beveled sub-dial between the 2 and 3 o'clock indices showing
// a condition icon, the current temp, and the day's hi/lo. Weather comes from
// the on-device Toybox.Weather API.
class WeatherDial {

    const POS_FRAC = 2.5 / 12.0;  // clock position (between 2 and 3)
    const POS_R    = 110;         // sub-dial center distance from dial center
    const DIAL_R   = 54;          // sub-dial radius
    const RIM      = 4;           // bezel thickness

    function draw(dc, cx, cy) {
        var p   = Geometry.polar(cx, cy, POS_R, POS_FRAC);
        var wcx = p[0];
        var wcy = p[1];

        SubDial.beveledFace(dc, wcx, wcy, DIAL_R, RIM);

        // --- weather data ---
        var tempF = null;
        var hiF   = null;
        var loF   = null;
        var cond  = null;
        if (Toybox has :Weather) {
            var c = Weather.getCurrentConditions();
            if (c != null) {
                if (c.temperature != null)     { tempF = cToF(c.temperature); }
                if (c.highTemperature != null) { hiF   = cToF(c.highTemperature); }
                if (c.lowTemperature != null)  { loF   = cToF(c.lowTemperature); }
                cond = c.condition;
            }
        }

        // condition icon
        drawIcon(dc, wcx, wcy - 30, cond);

        // current temperature (near center)
        dc.setColor(Palette.PRIMARY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(wcx, wcy + 2,
                    Fonts.vector(dc, (dc.getFontHeight(Graphics.FONT_XTINY) * 11) / 15),
                    (tempF != null) ? tempF.toString() + "°" : "--°",
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // day lo / hi, monochrome, with a gap around the separator
        var loStr = (loF != null) ? loF.toString() + "°" : "--°";
        var hiStr = (hiF != null) ? hiF.toString() + "°" : "--°";
        var hf    = Fonts.vector(dc, dc.getFontHeight(Graphics.FONT_XTINY) / 2);
        var y2    = wcy + 21;
        dc.setColor(Palette.TERTIARY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(wcx - 6, y2, hf, loStr,
                    Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(wcx, y2, hf, "/",
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(wcx + 6, y2, hf, hiStr,
                    Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // ---- condition icon: pick a drawn glyph from the Weather condition ----
    private function drawIcon(dc, cx, cy, cond) {
        var kind = "cloudy";
        if (cond != null) {
            if (cond == Weather.CONDITION_CLEAR) {
                kind = "clear";
            } else if (cond == Weather.CONDITION_PARTLY_CLOUDY) {
                kind = "partly";
            } else if (cond == Weather.CONDITION_RAIN || cond == Weather.CONDITION_THUNDERSTORMS) {
                kind = "rain";
            } else if (cond == Weather.CONDITION_SNOW) {
                kind = "snow";
            }
        }

        if (kind.equals("clear")) {
            drawSun(dc, cx, cy, 9);
        } else if (kind.equals("partly")) {
            drawSun(dc, cx - 3, cy - 1, 6);
            drawCloud(dc, cx + 5, cy + 5, 22, Palette.PRIMARY);
        } else if (kind.equals("rain")) {
            drawCloud(dc, cx, cy - 2, 25, Palette.PRIMARY);
            drawDrops(dc, cx, cy + 10);
        } else if (kind.equals("snow")) {
            drawCloud(dc, cx, cy - 2, 25, Palette.PRIMARY);
            drawFlakes(dc, cx, cy + 10);
        } else {
            drawCloud(dc, cx, cy, 27, Palette.PRIMARY);
        }
    }

    private function drawSun(dc, cx, cy, r) {
        dc.setColor(Palette.PRIMARY, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawCircle(cx, cy, r);          // outline body
        for (var k = 0; k < 8; k += 1) {
            var a = k * (Math.PI / 4.0);
            var ca = Math.cos(a);
            var sa = Math.sin(a);
            dc.drawLine(cx + (r + 2) * ca, cy + (r + 2) * sa,
                        cx + (r + 5) * ca, cy + (r + 5) * sa);
        }
    }

    // Outlined cloud: fill the silhouette, then carve a black inner copy
    // (eroded by the stroke width) so only a clean outline remains.
    private function drawCloud(dc, cx, cy, w, color) {
        var s = 2;  // outline stroke
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx - w * 0.26, cy + w * 0.05, w * 0.22);
        dc.fillCircle(cx + w * 0.02, cy - w * 0.12, w * 0.30);
        dc.fillCircle(cx + w * 0.30, cy + w * 0.04, w * 0.24);
        dc.fillRectangle(cx - w * 0.45, cy, w * 0.9, w * 0.22);

        dc.setColor(0x000000, Graphics.COLOR_TRANSPARENT);   // carve against the black face -> outline
        dc.fillCircle(cx - w * 0.26, cy + w * 0.05, w * 0.22 - s);
        dc.fillCircle(cx + w * 0.02, cy - w * 0.12, w * 0.30 - s);
        dc.fillCircle(cx + w * 0.30, cy + w * 0.04, w * 0.24 - s);
        dc.fillRectangle(cx - w * 0.45 + s, cy, w * 0.9 - 2 * s, w * 0.22 - s);
    }

    private function drawDrops(dc, cx, cy) {
        dc.setColor(Palette.SECONDARY, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        for (var i = -1; i <= 1; i += 1) {
            var x = cx + i * 6;
            dc.drawLine(x + 2, cy, x - 1, cy + 5);
        }
    }

    private function drawFlakes(dc, cx, cy) {
        dc.setColor(Palette.SECONDARY, Graphics.COLOR_TRANSPARENT);
        for (var i = -1; i <= 1; i += 1) {
            dc.fillCircle(cx + i * 6, cy + 2, 1);
        }
    }

    private function cToF(c) { return ((c * 9.0 / 5.0) + 32).toNumber(); }
}
