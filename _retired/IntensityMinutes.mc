import Toybox.ActivityMonitor;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;

// IntensityMinutes — Garmin weekly intensity minutes, printed directly on the
// dial at 6 o'clock (no sub-dial circle). Occupies the footprint the sun times
// and then Body Battery used. Two tiers: heading (bolt + INTENSITY) over the
// week's total with the weekly goal as a small suffix ("63 /150") — a bare
// intensity number means nothing without the goal beside it.
//
// Weekly, not daily, because Garmin's goal (and the whole metric) is a
// rolling-week target. Reads ActivityMonitor only: no location, no weather,
// no SensorHistory.
class IntensityMinutes {

    const IDX_INNER  = 50;    // chapter-ring INSET(2) + LENGTH(48)
    const GAP        = 15;    // gap inside the 6 index
    const RISE       = 18;    // stack lift (tuned when the gauge tier was dropped)
    const GOAL_FB    = 150;   // fallback weekly goal if the device reports none
    const SUFFIX_PAD = 4;     // space between the value and the /goal suffix
    const SUFFIX_DY  = 7;     // drop the suffix so it sits like a subscript

    function draw(dc, cx, cy) {
        var baseY    = cy + (cx - IDX_INNER - GAP);  // nearest point to 6 index
        var valueY   = baseY - 34 + RISE;
        var headingY = baseY - 60 + RISE;

        // ---- read weekly intensity minutes + goal ----
        var val  = null;
        var goal = GOAL_FB;
        var info = ActivityMonitor.getInfo();
        if (info != null) {
            if ((info has :activeMinutesWeek) && info.activeMinutesWeek != null
                    && info.activeMinutesWeek.total != null) {
                val = info.activeMinutesWeek.total.toNumber();
            }
            if ((info has :activeMinutesWeekGoal) && info.activeMinutesWeekGoal != null
                    && info.activeMinutesWeekGoal > 0) {
                goal = info.activeMinutesWeekGoal.toNumber();
            }
        }

        // goal met flips to ACCENT — same reserved use as the steps ring
        var col = (val != null && val >= goal) ? Palette.ACCENT : Palette.PRIMARY;

        drawHeading(dc, cx, headingY);
        drawValue(dc, cx, valueY, val, goal, col);
    }

    // heading: a small energy bolt + an INTENSITY label, centered as one group.
    private function drawHeading(dc, cx, y) {
        var f     = Fonts.vector(dc, (dc.getFontHeight(Graphics.FONT_XTINY) * 3) / 5);
        var label = "INTENSITY";
        var tw    = dc.getTextWidthInPixels(label, f);
        var boltW = 11;
        var pad   = 6;
        var startX = cx - ((boltW + pad + tw) / 2);

        drawBolt(dc, startX + (boltW / 2), y);
        dc.setColor(Palette.TERTIARY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(startX + boltW + pad, y, f, label,
                    Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // a compact lightning bolt, centered on (bx, by).
    private function drawBolt(dc, bx, by) {
        dc.setColor(Palette.SECONDARY, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon([
            [ bx + 1, by - 9 ],
            [ bx - 5, by + 1 ],
            [ bx,     by + 1 ],
            [ bx - 2, by + 9 ],
            [ bx + 6, by - 2 ],
            [ bx + 1, by - 2 ]
        ]);
    }

    // big weekly total + a small "/goal" suffix, centered together on cx.
    private function drawValue(dc, cx, y, val, goal, col) {
        var txt  = (val == null) ? "--" : val.toString();
        var numF = Fonts.vector(dc, (dc.getFontHeight(Graphics.FONT_MEDIUM) * 9) / 10);
        var sufF = Fonts.vector(dc, (dc.getFontHeight(Graphics.FONT_XTINY) * 3) / 5);
        var suf  = "/" + goal.toString();

        var numW = dc.getTextWidthInPixels(txt, numF);
        var sufW = dc.getTextWidthInPixels(suf, sufF);
        var startX = cx - ((numW + SUFFIX_PAD + sufW) / 2);

        dc.setColor(col, Graphics.COLOR_TRANSPARENT);
        dc.drawText(startX, y, numF, txt,
                    Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(Palette.TERTIARY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(startX + numW + SUFFIX_PAD, y + SUFFIX_DY, sufF, suf,
                    Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}
