import Toybox.Lang;
import Toybox.Application;
import Toybox.WatchUi;
import Toybox.Attention;

class MorseApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Dictionary?) as Void {
        // Watches without a vibration motor: fall back to audible Morse and
        // don't offer to turn sound off.
        if (!(Attention has :vibrate)) {
            Settings.setNum("sound", 2);
            Settings.setNum("soundAsked", 1);
        }
    }

    function onStop(state as Dictionary?) as Void {
    }

    // First launch opens on the sound question; choosing switches to the
    // main menu. Later launches open straight on the main menu.
    function getInitialView() {
        if (Settings.getNum("soundAsked", 0) == 0) {
            return [Menus.buildSoundPrompt(), new SoundPromptDelegate()];
        }
        return [Menus.buildMain(), new MainMenuDelegate()];
    }

    static function refreshMenu() as Void {
        Menus.refreshMain();
    }
}
