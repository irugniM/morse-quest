import Toybox.Lang;
import Toybox.WatchUi;

// Game input
//   UP = dot, DOWN = dash (short presses; holding START is a system hot key
//   on Instinct, so timing a long press isn't possible)
//   Pause ~1 s = next letter. START = submit now / replay / skip intro / again.
//   BACK = leave to the menu.
class MorseDelegate extends WatchUi.BehaviorDelegate {

    hidden var _game as MorseGame;

    function initialize(game as MorseGame) {
        BehaviorDelegate.initialize();
        _game = game;
    }

    // START via the raw key event (onSelect isn't delivered for it in the
    // simulator); onSelect is swallowed so it can't double-fire.
    function onKeyPressed(evt as WatchUi.KeyEvent) as Boolean {
        if (evt.getKey() == WatchUi.KEY_ENTER) {
            _game.onStart();
            return true;
        }
        return false;
    }

    function onSelect() as Boolean { return true; }

    function onPreviousPage() as Boolean {   // UP
        _game.key(".");
        return true;
    }

    function onNextPage() as Boolean {       // DOWN
        _game.key("-");
        return true;
    }

    function onMenu() as Boolean { return true; }

    function onBack() as Boolean {
        _game.stop();
        MorseApp.refreshMenu();
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }
}
