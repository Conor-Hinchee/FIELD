import Toybox.Application;
import Toybox.WatchUi;

// Entry point for the FIELD watch face.
class FieldApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state) {
    }

    function onStop(state) {
    }

    // Return the initial view shown on the watch.
    function getInitialView() {
        return [ new FieldView() ];
    }
}
