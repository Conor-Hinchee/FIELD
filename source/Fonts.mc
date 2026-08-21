import Toybox.Graphics;
import Toybox.Lang;

// Shared font helper: a scalable vector font at the requested pixel height,
// falling back to FONT_XTINY where vector fonts (or the faces) aren't available.
module Fonts {
    function vector(dc, size) {
        if (Graphics has :getVectorFont) {
            var faces = ["RobotoCondensedBold", "RobotoRegular", "RobotoCondensedRegular"];
            for (var i = 0; i < faces.size(); i += 1) {
                var vf = Graphics.getVectorFont({:face => faces[i], :size => size});
                if (vf != null) { return vf; }
            }
        }
        return Graphics.FONT_XTINY;
    }
}
