import Toybox.Graphics;
import Toybox.Math;

// CannonPinion — the center boss the hands mount on: a mostly-black dome whose
// top edge catches the light, capped by a small gray pin. Drawn last so it
// covers the hand pivots.
//
// Tunables live at the top.
class CannonPinion {

    const RADIUS = 16;   // boss radius
    const PIN_R  = 3;    // pin-cap radius
    const GRAY   = 102;  // shared gray: top-edge highlight + pin (0x66)

    function draw(dc, cx, cy) {
        var r = RADIUS;

        // Black dome with a top-lit vertical gradient: the gray sits on the top
        // edge and falls off steeply to a black core (steep cubic falloff).
        for (var dy = -r; dy <= r; dy += 1) {
            var hw = Math.sqrt((r * r - dy * dy).toFloat()).toNumber();
            if (hw <= 0) { continue; }
            var t = (dy + r) / (2.0 * r);      // 0 at top, 1 at bottom
            var f = 1.0 - t;
            var b = (GRAY * f * f * f).toNumber();
            dc.setColor((b << 16) | (b << 8) | b, Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(cx - hw, cy + dy, (2 * hw) + 1, 1);
        }

        // pin cap: small gray circle matching the top-edge gray
        var g = (GRAY << 16) | (GRAY << 8) | GRAY;
        dc.setColor(g, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx, cy, PIN_R);
    }
}
