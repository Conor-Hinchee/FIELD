import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.SensorHistory;

// BodyBattery — Garmin Body Battery (0-100) printed directly on the dial at
// 6 o'clock (no sub-dial circle). Same three-tier footprint the sun times used:
// heading (bolt + BODY) -> big value + trend chevron -> a segmented linear
// gauge hugging the 6 index. The linear gauge deliberately echoes the device
// battery's circular segmented ring: matched pair, different geometry. Reads
// from SensorHistory, so there is NO location / weather dependency (which is
// what was breaking sunrise/sunset on device).
class BodyBattery {

    const IDX_INNER = 50;    // chapter-ring INSET(2) + LENGTH(48)
    const GAP       = 15;    // gap inside the 6 index (matches the old sun stack)

    const SEG_N     = 10;    // segments in the linear gauge
    const SEG_W     = 3;     // filled-bar width
    const SEG_H     = 9;     // filled-bar height
    const SEG_PITCH = 5.7;   // slot spacing
    const SEG_DOT   = 1.6;   // spent-segment ball radius
    const OFF_GRAY  = 0x505050;

    function draw(dc, cx, cy) {
        var baseY    = cy + (cx - IDX_INNER - GAP);  // nearest point to 6 index
        var gaugeTop = baseY - 8;
        var valueY   = baseY - 34;
        var headingY = baseY - 60;

        // ---- read Body Battery + short-term trend ----
        var val   = null;
        var trend = 0;   // +1 recovering, -1 draining, 0 flat / unknown
        if (Toybox has :SensorHistory
                && (SensorHistory has :getBodyBatteryHistory)) {
            var iter = SensorHistory.getBodyBatteryHistory({
                :period => 3,
                :order  => SensorHistory.ORDER_NEWEST_FIRST
            });
            if (iter != null) {
                var s0 = iter.next();
                if (s0 != null && s0.data != null) {
                    val = s0.data.toNumber();
                    var s1 = iter.next();
                    if (s1 != null && s1.data != null) {
                        var prev = s1.data.toNumber();
                        if (val > prev)      { trend =  1; }
                        else if (val < prev) { trend = -1; }
                    }
                }
            }
        }

        var col = (val != null && val <= 15) ? Palette.ACCENT : Palette.PRIMARY;

        drawHeading(dc, cx, headingY);
        drawValue(dc, cx, valueY, val, trend, col);
        drawGauge(dc, cx, gaugeTop, val, col);
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

    // big value + trend chevron to its right.
    private function drawValue(dc, cx, y, val, trend, col) {
        var txt = (val == null) ? "--" : val.toString();
        dc.setColor(col, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, y,
                    Fonts.vector(dc, (dc.getFontHeight(Graphics.FONT_MEDIUM) * 9) / 10),
                    txt,
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        if (val != null && trend != 0) {
            var tc = (val <= 15) ? Palette.ACCENT : Palette.TERTIARY;
            drawTrend(dc, cx + 30, y, trend, tc);
        }
    }

    private function drawTrend(dc, x, y, dir, color) {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(3);
        if (dir > 0) {
            dc.drawLine(x - 5, y + 4, x,     y - 3);
            dc.drawLine(x,     y - 3, x + 5, y + 4);
        } else {
            dc.drawLine(x - 5, y - 4, x,     y + 3);
            dc.drawLine(x,     y + 3, x + 5, y - 4);
        }
    }

    // segmented linear gauge: filled bars for the level, dim balls for the rest.
    private function drawGauge(dc, cx, top, val, col) {
        var startX = cx - 24;
        var filled = (val == null)
            ? 0
            : ((val * SEG_N) / 100.0 + 0.5).toNumber();
        if (filled > SEG_N) { filled = SEG_N; }

        for (var i = 0; i < SEG_N; i += 1) {
            var slotX = startX + i * SEG_PITCH;
            if (i < filled) {
                dc.setColor(col, Graphics.COLOR_TRANSPARENT);
                dc.fillRectangle(slotX, top, SEG_W, SEG_H);
            } else {
                dc.setColor(OFF_GRAY, Graphics.COLOR_TRANSPARENT);
                dc.fillCircle(slotX + SEG_W / 2, top + SEG_H / 2, SEG_DOT);
            }
        }
    }
}
