import Toybox.Lang;
import Toybox.Application;
import Toybox.WatchUi;
import Toybox.Attention;

class MorseApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Dictionary?) as Void {
        // Watches without a vibration motor: fall back to audible Morse.
        if (!(Attention has :vibrate) && Settings.sound() != 2) {
            Settings.setNum("sound", 2);
        }
    }

    function onStop(state as Dictionary?) as Void {
    }

    function getInitialView() {
        return [Menus.buildMain(), new MainMenuDelegate()];
    }

    static function refreshMenu() as Void {
        Menus.refreshMain();
    }
}
