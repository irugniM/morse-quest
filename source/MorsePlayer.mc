import Toybox.Lang;
import Toybox.Timer;

// Plays text as vibration, one symbol per Timer tick, so the VibeProfile
// array never holds more than one entry (some devices cap it at ~8).
class MorsePlayer {

    hidden var _timer as Timer.Timer;
    hidden var _steps as Array<Array<Number> > = [] as Array<Array<Number> >;
    hidden var _i as Number = 0;
    hidden var _done as Method() as Void or Null = null;

    function initialize() {
        _timer = new Timer.Timer();
    }

    function play(text as String, leadInMs as Number, done as Method() as Void) as Void {
        _timer.stop();
        _steps = Morse.timing(text, Settings.wpm(), Settings.spacing());
        _i = 0;
        _done = done;
        _timer.start(method(:tick), leadInMs < 50 ? 50 : leadInMs, false);
    }

    function tick() as Void {
        if (_i >= _steps.size()) {
            var d = _done;
            _done = null;
            if (d != null) { d.invoke(); }
            return;
        }
        var s = _steps[_i];
        _i++;
        Feedback.symbol(s[0]);
        var wait = s[0] + s[1];
        _timer.start(method(:tick), wait < 50 ? 50 : wait, false);
    }

    function stop() as Void {
        _timer.stop();
        _done = null;
    }
}
