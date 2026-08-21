import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.Weather;
import Toybox.Activity;

// SunTimes — sunrise / sunset printed directly on the dial at 6 o'clock (no
// sub-dial circle). Sits GAP px inside the 6 index, mirroring the battery's
// gap from the 12 index. Times are computed from location with the standard
// sunrise equation, since Garmin has no built-in sun-times call.
class SunTimes {

    const IDX_INNER = 50;   // chapter-ring INSET(2) + LENGTH(48)
    const GAP       = 15;   // gap inside the 6 index (matches battery)
    const ZENITH    = 90.833;

    function draw(dc, cx, cy) {
        var baseY = cy + (cx - IDX_INNER - GAP);  // nearest point to the 6 index
        var setY  = baseY - 11;                   // sunset row (lower)
        var riseY = setY - 26;                    // sunrise row (upper)

        // location + date
        var loc = getLocation();
        var tz  = System.getClockTime().timeZoneOffset / 3600.0;
        var now = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var n   = dayOfYear(now.year, now.month, now.day);

        var rise = null;
        var set  = null;
        if (loc != null) {
            rise = computeSun(true,  loc[0], loc[1], tz, n);
            set  = computeSun(false, loc[0], loc[1], tz, n);
        }

        drawHeadingIcon(dc, cx, riseY - 23);

        var font = Fonts.vector(dc, (dc.getFontHeight(Graphics.FONT_XTINY) * 3) / 5);
        drawRow(dc, cx, riseY, true,  fmt(rise), font);
        drawRow(dc, cx, setY,  false, fmt(set),  font);
    }

    // heading glyph: a sun rising over an ocean horizon — a sun dome on a wide
    // horizon line, with a little water shimmer below.
    private function drawHeadingIcon(dc, hx, hy) {
        dc.setColor(Palette.PRIMARY, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);

        // sun dome above the horizon
        dc.drawArc(hx, hy, 7, Graphics.ARC_COUNTER_CLOCKWISE, 0, 180);

        // a few rays above the dome
        dc.drawLine(hx,     hy - 11, hx,      hy - 14);
        dc.drawLine(hx - 9, hy - 8,  hx - 11, hy - 10);
        dc.drawLine(hx + 9, hy - 8,  hx + 11, hy - 10);

        // horizon line (wide ocean surface)
        dc.drawLine(hx - 18, hy, hx + 18, hy);

        // shimmer / reflection on the water
        dc.drawLine(hx - 5, hy + 4, hx + 5, hy + 4);
        dc.drawLine(hx - 3, hy + 7, hx + 3, hy + 7);
    }

    // one row: sun-on-horizon glyph + time, centered as a pair
    private function drawRow(dc, cx, y, up, text, font) {
        drawSunGlyph(dc, cx - 22, y, up);
        dc.setColor(Palette.TERTIARY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx - 10, y, font, text,
                    Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    private function drawSunGlyph(dc, cx, cy, up) {
        dc.setColor(Palette.PRIMARY, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawLine(cx - 8, cy + 4, cx + 8, cy + 4);                        // horizon
        dc.drawArc(cx, cy + 4, 5, Graphics.ARC_COUNTER_CLOCKWISE, 15, 165); // dome
        // little rays over the sun
        dc.drawLine(cx,     cy - 3, cx,     cy - 6);
        dc.drawLine(cx - 5, cy - 1, cx - 7, cy - 3);
        dc.drawLine(cx + 5, cy - 1, cx + 7, cy - 3);
        // direction arrow to the left (up = sunrise, down = sunset)
        if (up) {
            dc.drawLine(cx - 12, cy + 3, cx - 12, cy - 3);
            dc.drawLine(cx - 12, cy - 3, cx - 14, cy - 1);
            dc.drawLine(cx - 12, cy - 3, cx - 10, cy - 1);
        } else {
            dc.drawLine(cx - 12, cy - 3, cx - 12, cy + 3);
            dc.drawLine(cx - 12, cy + 3, cx - 14, cy + 1);
            dc.drawLine(cx - 12, cy + 3, cx - 10, cy + 1);
        }
    }

    // ---- sun-times math (Almanac sunrise equation) ----
    private function computeSun(isRise, lat, lon, tz, n) {
        var D2R = Math.PI / 180.0;
        var R2D = 180.0 / Math.PI;

        var lngHour = lon / 15.0;
        var t = isRise ? (n + ((6 - lngHour) / 24.0)) : (n + ((18 - lngHour) / 24.0));
        var m = (0.9856 * t) - 3.289;
        var l = m + (1.916 * Math.sin(m * D2R)) + (0.020 * Math.sin(2 * m * D2R)) + 282.634;
        l = normDeg(l);

        var ra = R2D * Math.atan(0.91764 * Math.tan(l * D2R));
        ra = normDeg(ra);
        var lQuad  = Math.floor(l / 90.0) * 90.0;
        var raQuad = Math.floor(ra / 90.0) * 90.0;
        ra = (ra + (lQuad - raQuad)) / 15.0;

        var sinDec = 0.39782 * Math.sin(l * D2R);
        var cosDec = Math.cos(Math.asin(sinDec));
        var cosH = (Math.cos(ZENITH * D2R) - (sinDec * Math.sin(lat * D2R)))
                 / (cosDec * Math.cos(lat * D2R));
        if (cosH > 1.0 || cosH < -1.0) { return null; }  // no rise/set today

        var h = isRise ? (360.0 - R2D * Math.acos(cosH)) : (R2D * Math.acos(cosH));
        h = h / 15.0;

        var localT = (h + ra - (0.06571 * t) - 6.622) - lngHour + tz;
        return normHours(localT);
    }

    private function getLocation() {
        // real location first (weather station, then last GPS fix)
        if (Toybox has :Weather) {
            var c = Weather.getCurrentConditions();
            if (c != null && c.observationLocationPosition != null) {
                return c.observationLocationPosition.toDegrees();
            }
        }
        var act = Activity.getActivityInfo();
        if (act != null && act.currentLocation != null) {
            return act.currentLocation.toDegrees();
        }
        // fallback until a fix is available: estimate longitude from the
        // timezone, default a temperate latitude (approximate, self-corrects
        // once real coordinates arrive).
        var tz = System.getClockTime().timeZoneOffset / 3600.0;
        return [ 40.0, tz * 15.0 ];
    }

    private function dayOfYear(y, m, d) {
        var cum = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334];
        var n = cum[m - 1] + d;
        if (m > 2 && (((y % 4) == 0 && (y % 100) != 0) || (y % 400) == 0)) { n += 1; }
        return n;
    }

    private function normDeg(x) {
        while (x < 0.0)    { x += 360.0; }
        while (x >= 360.0) { x -= 360.0; }
        return x;
    }

    private function normHours(x) {
        while (x < 0.0)   { x += 24.0; }
        while (x >= 24.0) { x -= 24.0; }
        return x;
    }

    private function fmt(h) {
        if (h == null) { return "--:--"; }
        var hh = h.toNumber();
        var mm = ((h - hh) * 60.0 + 0.5).toNumber();
        if (mm >= 60) { mm -= 60; hh += 1; }
        hh = hh % 24;
        var suffix = (hh < 12) ? "a" : "p";
        var h12 = hh % 12;
        if (h12 == 0) { h12 = 12; }
        var ms = (mm < 10) ? "0" + mm.toString() : mm.toString();
        return h12.toString() + ":" + ms + suffix;
    }
}
