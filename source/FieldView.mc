import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Math;
import Toybox.Lang;
import Toybox.Time;
import Toybox.Time.Gregorian;

// FIELD — outer ring only, on jet black.
// Thin silver hour batons with a beveled edge; 12 o'clock is a pair of
// rectangles set side by side. Subordinate minute ticks fill the track.
class FieldView extends WatchUi.WatchFace {

    private var mCx, mCy;
    private var mLowPower = false;

    function initialize() { WatchFace.initialize(); }

    function onLayout(dc) {
        mCx = dc.getWidth()  / 2;
        mCy = dc.getHeight() / 2;
    }

    function onUpdate(dc) {
        dc.setColor(Palette.BG, Palette.BG);
        dc.clear();
        if (dc has :setAntiAlias) { dc.setAntiAlias(true); }

        drawTicks(dc);
        drawHands(dc);
    }

    // ---- outer tick ring: silver hour batons, subtle minute ticks ----
    function drawTicks(dc) {
        var rOut = mCx - 2;   // run the ring right to the screen edge
        var hw   = 5;   // baton half-width (slimmer)
        var len  = 48;  // baton length (longer)

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
        fillBaton(dc, fraction, rOuter - 2, rInner + 2, hw * 0.5,     off, Palette.HOUR_HI);
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

    // ---- hands: broad chrome blades (arrow minute, blunt hour) ----
    function drawHands(dc) {
        var now   = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var hourF = ((now.hour % 12) + (now.min / 60.0)) / 12.0;
        var minF  = (now.min + (now.sec / 60.0)) / 60.0;
        var secF  = now.sec / 60.0;

        // hour: shorter blade, blunt squared tip (tipLen 0)
        drawBladeHand(dc, hourF, 100, 8, 24, 0);
        // minute: longer blade, pointed spear tip
        drawBladeHand(dc, minF,  150, 7, 26, 26);

        // second hand: thin bright sweep with a counterweight (skip in sleep)
        if (!mLowPower) {
            var tip  = Geometry.polar(mCx, mCy, 158, secF);
            var tail = Geometry.polar(mCx, mCy, -38, secF);
            dc.setColor(Palette.HOUR_HI, Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(2);
            dc.drawLine(tail[0], tail[1], tip[0], tip[1]);
            var cw = Geometry.polar(mCx, mCy, -28, secF);
            dc.fillCircle(cw[0], cw[1], 4);
        }

        // center cap: dark knob, thin silver ring, tiny bright pupil
        dc.setColor(Palette.HOUR, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(mCx, mCy, 11);
        dc.setColor(Palette.BG, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(mCx, mCy, 9);
        dc.setColor(Palette.HOUR_HI, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(mCx, mCy, 2);
    }

    // A broad chrome blade: dark outline -> silver body -> bright center ridge,
    // with a black skeleton slot near the base. tipLen 0 = blunt, >0 = pointed.
    function drawBladeHand(dc, fraction, L, hw, tailLen, tipLen) {
        var a  = (fraction * 2.0 * Math.PI) - (Math.PI / 2.0);
        var ca = Math.cos(a);
        var sa = Math.sin(a);
        var px = -sa;
        var py =  ca;

        fillBlade(dc, ca, sa, px, py, hw + 2, L + 2, tailLen + 1, tipLen, Palette.HOUR_EDGE);
        fillBlade(dc, ca, sa, px, py, hw,     L,     tailLen,     tipLen, Palette.HOUR);
        // bright raised ridge down the center (blunt, stops short of the tip)
        fillBlade(dc, ca, sa, px, py, hw * 0.34, L - 6, tailLen - 4, 0, Palette.HOUR_HI);
        // black skeleton slot near the base
        fillSlot(dc, ca, sa, px, py, -tailLen + 6, L * 0.32, hw * 0.44, Palette.BG);
    }

    function fillBlade(dc, ca, sa, px, py, hw, L, tailLen, tipLen, color) {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        if (tipLen > 0) {
            dc.fillPolygon([
                [ mCx - tailLen * ca + hw * px, mCy - tailLen * sa + hw * py ],
                [ mCx + (L - tipLen) * ca + hw * px, mCy + (L - tipLen) * sa + hw * py ],
                [ mCx + L * ca, mCy + L * sa ],
                [ mCx + (L - tipLen) * ca - hw * px, mCy + (L - tipLen) * sa - hw * py ],
                [ mCx - tailLen * ca - hw * px, mCy - tailLen * sa - hw * py ]
            ]);
        } else {
            dc.fillPolygon([
                [ mCx - tailLen * ca + hw * px, mCy - tailLen * sa + hw * py ],
                [ mCx + L * ca + hw * px, mCy + L * sa + hw * py ],
                [ mCx + L * ca - hw * px, mCy + L * sa - hw * py ],
                [ mCx - tailLen * ca - hw * px, mCy - tailLen * sa - hw * py ]
            ]);
        }
    }

    function fillSlot(dc, ca, sa, px, py, u0, u1, hs, color) {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon([
            [ mCx + u0 * ca + hs * px, mCy + u0 * sa + hs * py ],
            [ mCx + u1 * ca + hs * px, mCy + u1 * sa + hs * py ],
            [ mCx + u1 * ca - hs * px, mCy + u1 * sa - hs * py ],
            [ mCx + u0 * ca - hs * px, mCy + u0 * sa - hs * py ]
        ]);
        dc.fillCircle(mCx + u0 * ca, mCy + u0 * sa, hs);
        dc.fillCircle(mCx + u1 * ca, mCy + u1 * sa, hs);
    }

    function onEnterSleep() { mLowPower = true;  WatchUi.requestUpdate(); }
    function onExitSleep()  { mLowPower = false; WatchUi.requestUpdate(); }
}
