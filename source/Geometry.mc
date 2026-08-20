import Toybox.Math;

// Polar helpers for the radial layout.
// fraction is in [0,1): 0 = 12 o'clock, 0.25 = 3 o'clock, increasing clockwise.
module Geometry {

    // Returns [x, y] on a circle of the given radius around (cx, cy).
    // A negative radius yields the point on the opposite side of center
    // (handy for hand counterweights / tails).
    function polar(cx, cy, radius, fraction) {
        var theta = (fraction * 2.0 * Math.PI) - (Math.PI / 2.0);
        return [ cx + radius * Math.cos(theta),
                 cy + radius * Math.sin(theta) ];
    }
}
