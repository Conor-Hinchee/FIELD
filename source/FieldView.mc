import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Math;
import Toybox.Lang;

// FIELD — outer ring only, on jet black.
// Thin silver hour batons with a beveled edge; 12 o'clock is a pair of
// rectangles set side by side. Subordinate minute ticks fill the track.
class FieldView extends WatchUi.WatchFace {

    private var mCx, mCy;

    function initialize() { WatchFace.initialize(); }

    function onLayout(dc) {
        mCx = dc.getWidth()  / 2;
        mCy = dc.getHeight() / 2;
    }

    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        if (dc has :setAntiAlias) { dc.setAntiAlias(true); }

        drawTicks(dc);
    }

    // ---- outer tick ring: silver hour batons, subtle minute ticks ----
    function drawTicks(dc) {
        var rOut = mCx - 8;
        var hw   = 4;   // baton half-width
        var len  = 40;  // baton length (longer)

        // minute track: crisp mid-gray, clearly subordinate to the batons
        dc.setColor(0x8A8A8A, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        for (var i = 0; i < 60; i += 1) {
            if ((i % 5) == 0) { continue; }
            var f  = i / 60.0;
            var p1 = Geometry.polar(mCx, mCy, rOut, f);
            var p2 = Geometry.polar(mCx, mCy, rOut - 10, f);
            dc.drawLine(p1[0], p1[1], p2[0], p2[1]);
        }

        // hour batons
        for (var h = 0; h < 12; h += 1) {
            if (h == 0) {
                // 12 o'clock: two beveled bars flush against each other
                // (faces touch, dark rims meet — no gap, no background pixel).
                drawBaton(dc, 0.0, rOut, rOut - len, hw, -hw);
                drawBaton(dc, 0.0, rOut, rOut - len, hw,  hw);
            } else {
                drawBaton(dc, h / 12.0, rOut, rOut - len, hw, 0);
            }
        }
    }

    // Beveled baton, three layers so it reads as raised brushed metal:
    //   dark rim (largest) -> silver face -> bright specular core (inset).
    // `off` shifts the baton along the tangent (perpendicular to its radius).
    function drawBaton(dc, fraction, rOuter, rInner, hw, off) {
        fillBaton(dc, fraction, rOuter + 2, rInner - 2, hw + 2,       off, Palette.HOUR_EDGE);
        fillBaton(dc, fraction, rOuter,     rInner,     hw,           off, Palette.HOUR);
        fillBaton(dc, fraction, rOuter - 2, rInner + 2, hw * 0.42,    off, Palette.HOUR_HI);
    }

    function fillBaton(dc, fraction, rOuter, rInner, hw, off, color) {
        var a  = (fraction * 2.0 * Math.PI) - (Math.PI / 2.0);
        var ca = Math.cos(a);
        var sa = Math.sin(a);
        var px = -sa;  // tangent (perpendicular) direction
        var py =  ca;
        var ox = mCx + rOuter * ca + off * px, oy = mCy + rOuter * sa + off * py;
        var ix = mCx + rInner * ca + off * px, iy = mCy + rInner * sa + off * py;
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon([
            [ ox + px * hw, oy + py * hw ],
            [ ox - px * hw, oy - py * hw ],
            [ ix - px * hw, iy - py * hw ],
            [ ix + px * hw, iy + py * hw ]
        ]);
    }

    function onEnterSleep() { WatchUi.requestUpdate(); }
    function onExitSleep()  { WatchUi.requestUpdate(); }
}
