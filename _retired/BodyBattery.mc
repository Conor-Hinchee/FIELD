import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.SensorHistory;

// BodyBattery — Garmin Body Battery (0-100) printed directly on the dial at
// 6 o'clock (no sub-dial circle). Two tiers: heading (bolt + BODY) over the
// big value. The trend chevron and the segmented linear gauge were removed
// 2026-09-01 — just the number now. Reads from SensorHistory, so there is NO
// location / weather dependency (which is what was breaking sunrise/sunset on
// device).
class BodyBattery {

    const IDX_INNER = 50;    // chapter-ring INSET(2) + LENGTH(48)
    const GAP       = 15;    // gap inside the 6 index (matches the old sun stack)
    const RISE      = 18;    // lift the stack now that the gauge tier is gone

    function draw(dc, cx, cy) {
        var baseY    = cy + (cx - IDX_INNER - GAP);  // nearest point to 6 index
        var valueY   = baseY - 34 + RISE;
        var headingY = baseY - 60 + RISE;

        // ---- read Body Battery ----
        var val = null;
        if (Toybox has :SensorHistory
                && (SensorHistory has :getBodyBatteryHistory)) {
            var iter = SensorHistory.getBodyBatteryHistory({
                :period => 1,
                :order  => SensorHistory.ORDER_NEWEST_FIRST
            });
            if (iter != null) {
                var s0 = iter.next();
                if (s0 != null && s0.data != null) {
                    val = s0.data.toNumber();
                }
            }
        }

        var col = (val != null && val <= 15) ? Palette.ACCENT : Palette.PRIMARY;

        drawHeading(dc, cx, headingY);
        drawValue(dc, cx, valueY, val, col);
    }

    // heading: a small energy bolt + a BODY label, in the muted tiers.
    private function drawHeading(dc, cx, y) {
        drawBolt(dc, cx - 27, y);
        dc.setColor(Palette.TERTIARY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx - 15, y,
                    Fonts.vector(dc, (dc.getFontHeight(Graphics.FONT_XTINY) * 3) / 5),
                    "BODY",
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

    private function drawValue(dc, cx, y, val, col) {
        var txt = (val == null) ? "--" : val.toString();
        dc.setColor(col, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, y,
                    Fonts.vector(dc, (dc.getFontHeight(Graphics.FONT_MEDIUM) * 9) / 10),
                    txt,
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}
