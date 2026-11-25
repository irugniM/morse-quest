import Toybox.Lang;
import Toybox.Application;
import Toybox.WatchUi;
import Toybox.Attention;
import Toybox.Timer;

class MorseApp extends Application.AppBase {

    // Delay before the first-launch sound question, so the START press that
    // opened the app can't answer it by accident.
    const SOUND_PROMPT_DELAY_MS = 800;

    hidden var _promptTimer as Timer.Timer or Null = null;

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
        if (_promptTimer != null) { (_promptTimer as Timer.Timer).stop(); }
    }

    function getInitialView() {
        if (Settings.getNum("soundAsked", 0) == 0) {
            var t = new Timer.Timer();
            t.start(method(:askSound), SOUND_PROMPT_DELAY_MS, false);
            _promptTimer = t;
        }
        return [Menus.buildMain(), new MainMenuDelegate()];
    }

    function askSound() as Void {
        if (Settings.getNum("soundAsked", 0) != 0) { return; }
        var m = new WatchUi.Menu2({:title => "Sound"});
        m.addItem(new WatchUi.MenuItem("Sound on", "beeps for right/wrong", :soundOn, null));
        m.addItem(new WatchUi.MenuItem("Sound off", "vibration only", :soundOff, null));
        WatchUi.pushView(m, new SoundPromptDelegate(), WatchUi.SLIDE_UP);
    }

    static function refreshMenu() as Void {
        Menus.refreshMain();
    }
}
