import Toybox.Lang;
import Toybox.Timer;
import Toybox.System;
import Toybox.Math;
import Toybox.Time;
import Toybox.WatchUi;

enum GameMode {
    MODE_LESSON,   // single characters at the current level, can level up
    MODE_WORDS,    // short words made only of unlocked characters
    MODE_DAILY,    // 5 words seeded by date, once per day, keeps a streak
    MODE_TIME      // buzz the current time in Morse (no answer)
}

enum GameState {
    GS_INTRO,      // lesson intro: show + vibrate each new character
    GS_PLAYING,    // vibrating the item, input ignored
    GS_LISTENING,  // UP = dot, DOWN = dash, pause = next letter, START = submit
    GS_RESULT,     // feedback (and replay of the answer when wrong)
    GS_DONE        // summary
}

class MorseGame {

    const LESSON_ROUNDS = 20;
    const WORD_ROUNDS = 10;
    const DAILY_ROUNDS = 5;
    const PASS_PERCENT = 90;

    hidden const LEAD_IN_MS = 800;
    hidden const LETTER_PAUSE_MS = 1000;   // pause after a key that ends a letter
    hidden const ANSWER_PAUSE_MS = 2500;   // pause that ends an incomplete answer
    hidden const FIRST_KEY_MS = 5000;      // wait for the first key
    hidden const RIGHT_PAUSE_MS = 1300;
    hidden const WRONG_PAUSE_MS = 1500;

    var mode as GameMode;
    var state as GameState = GS_PLAYING;

    // Session
    var round as Number = 0;               // items finished
    var total as Number = 0;
    var correct as Number = 0;
    var score as Number = 0;
    var combo as Number = 0;
    var bestCombo as Number = 0;
    var lastGain as Number = 0;

    // Current item
    var target as String = "";
    var letters as Array<String> = [] as Array<String>;  // decoded answer so far
    var buf as String = "";                // symbols of the letter being entered
    var lastCorrect as Boolean = false;
    var replaying as Boolean = false;

    // Lesson
    var level as Number = 1;
    var pool as String = "";
    var newChars as String = "";
    var introIdx as Number = 0;
    var leveledUp as Boolean = false;
    var newBest as Boolean = false;

    // Daily
    var streak as Number = 0;
    var alreadyDone as Boolean = false;

    // Time
    var timeText as String = "";

    hidden var _player as MorsePlayer;
    hidden var _timer as Timer.Timer;
    hidden var _items as Array<String> = [] as Array<String>;
    hidden var _listenAt as Number = 0;
    hidden var _react as Number = 0;

    function initialize(m as GameMode) {
        mode = m;
        _player = new MorsePlayer();
        _timer = new Timer.Timer();
    }

    // ---------- setup ----------

    function start() as Void {
        round = 0; correct = 0; score = 0; combo = 0; bestCombo = 0;
        leveledUp = false; newBest = false; alreadyDone = false;
        level = Settings.level();
        pool = Morse.lettersFor(level);
        newChars = Morse.newLettersFor(level);

        if (mode == MODE_LESSON) {
            total = LESSON_ROUNDS;
            introIdx = 0;
            state = GS_INTRO;
            WatchUi.requestUpdate();
            playIntro();
            return;
        }
        if (mode == MODE_WORDS) {
            total = WORD_ROUNDS;
            _items = pickWords(WORD_ROUNDS, Math.rand());
        } else if (mode == MODE_DAILY) {
            total = DAILY_ROUNDS;
            streak = Settings.getNum("streak", 0);
            if (Settings.getNum("dailyDay", -1) == today()) {
                alreadyDone = true;
                score = Settings.getNum("dailyScore", 0);
                state = GS_DONE;
                WatchUi.requestUpdate();
                return;
            }
            _items = pickWords(DAILY_ROUNDS, today() * 7919 + 17);
        } else {
            startTime();
            return;
        }
        nextItem();
    }

    static function today() as Number {
        return (Time.today().value() / 86400) as Number;
    }

    // Words using unlocked characters only; falls back to the whole list if
    // too few (very early levels) so the mode is never empty.
    hidden function pickWords(n as Number, seed as Number) as Array<String> {
        var src = Morse.wordsFor(pool);
        if (src.size() < 4) { src = Morse.WORDS; }
        var out = [] as Array<String>;
        var s = seed.abs();
        for (var i = 0; i < n; i++) {
            s = (s * 1103515245 + 12345) & 0x7FFFFFFF;
            out.add(src[s % src.size()]);
        }
        return out;
    }

    // Lesson pick: new characters are drilled more, and so are weak ones.
    hidden function pickLetter() as String {
        var weights = [] as Array<Number>;
        var sum = 0;
        for (var i = 0; i < pool.length(); i++) {
            var c = pool.substring(i, i + 1) as String;
            var w = 2;
            if (newChars.find(c) != null) { w += 4; }
            var e = Settings.errorRate(c);
            if (e > 0) { w += e / 15; }
            weights.add(w);
            sum += w;
        }
        var r = Math.rand().abs() % sum;
        for (var i = 0; i < weights.size(); i++) {
            r -= weights[i];
            if (r < 0) { return pool.substring(i, i + 1) as String; }
        }
        return pool.substring(0, 1) as String;
    }

    // ---------- lesson intro ----------

    hidden function playIntro() as Void {
        var c = newChars.substring(introIdx, introIdx + 1) as String;
        target = c;
        _player.play(c + " " + c, LEAD_IN_MS, method(:afterIntroChar));
    }

    function afterIntroChar() as Void {
        if (state != GS_INTRO) { return; }
        introIdx++;
        if (introIdx < newChars.length()) {
            _timer.start(method(:introNext), 900, false);
        } else {
            _timer.start(method(:nextItem), 1200, false);
        }
    }

    function introNext() as Void {
        if (state != GS_INTRO) { return; }
        WatchUi.requestUpdate();
        playIntro();
    }

    // ---------- time ----------

    hidden function startTime() as Void {
        var t = System.getClockTime();
        var h = t.hour;
        if (!System.getDeviceSettings().is24Hour) {
            h = h % 12;
            if (h == 0) { h = 12; }
        }
        timeText = h.toString() + " " + t.min.format("%02d");
        total = 1;
        target = timeText;
        state = GS_PLAYING;
        WatchUi.requestUpdate();
        _player.play(timeText, LEAD_IN_MS, method(:afterTime));
    }

    function afterTime() as Void {
        state = GS_DONE;
        WatchUi.requestUpdate();
    }

    // ---------- rounds ----------

    function nextItem() as Void {
        _timer.stop();
        if (round >= total) { finishSession(); return; }
        target = (mode == MODE_LESSON) ? pickLetter() : _items[round];
        letters = [] as Array<String>;
        buf = "";
        replaying = false;
        state = GS_PLAYING;
        WatchUi.requestUpdate();
        _player.play(target, LEAD_IN_MS, method(:beginListening));
    }

    function replay() as Void {
        if (state == GS_LISTENING && letters.size() == 0 && buf.equals("")) {
            _timer.stop();
            state = GS_PLAYING;
            WatchUi.requestUpdate();
            _player.play(target, 300, method(:beginListening));
        }
    }

    function beginListening() as Void {
        state = GS_LISTENING;
        _listenAt = System.getTimer();
        _react = 0;
        WatchUi.requestUpdate();
        _timer.start(method(:submit), FIRST_KEY_MS + 1000 * target.length(), false);
    }

    function key(sym as String) as Void {
        if (state != GS_LISTENING) { return; }
        if (_react == 0) { _react = System.getTimer() - _listenAt; }
        buf += sym;
        WatchUi.requestUpdate();
        _timer.stop();
        _timer.start(method(:commitLetter), LETTER_PAUSE_MS, false);
    }

    function commitLetter() as Void {
        if (state != GS_LISTENING) { return; }
        if (!buf.equals("")) {
            letters.add(Morse.decode(buf));
            buf = "";
        }
        WatchUi.requestUpdate();
        if (letters.size() >= targetLen()) {
            submit();
        } else {
            _timer.start(method(:submit), ANSWER_PAUSE_MS, false);
        }
    }

    hidden function targetLen() as Number {
        return target.length();
    }

    function answer() as String {
        var s = "";
        for (var i = 0; i < letters.size(); i++) { s += letters[i]; }
        return s;
    }

    function submit() as Void {
        if (state != GS_LISTENING) { return; }
        _timer.stop();
        if (!buf.equals("")) {
            letters.add(Morse.decode(buf));
            buf = "";
        }
        var a = answer();
        lastCorrect = a.equals(target);
        round++;

        // Per-character stats (position by position).
        for (var i = 0; i < target.length(); i++) {
            var c = target.substring(i, i + 1) as String;
            var ok = i < a.length() && a.substring(i, i + 1).equals(c);
            Settings.recordLetter(c, ok);
        }

        // Score: 10 per character, combo multiplier x1..x3, +5 for a quick start.
        lastGain = 0;
        if (lastCorrect) {
            correct++;
            combo++;
            if (combo > bestCombo) { bestCombo = combo; }
            var mult = 1 + combo / 5;
            if (mult > 3) { mult = 3; }
            lastGain = 10 * target.length() * mult + (_react > 0 && _react < 1500 ? 5 : 0);
            score += lastGain;
            Feedback.right();
            state = GS_RESULT;
            WatchUi.requestUpdate();
            _timer.start(method(:nextItem), RIGHT_PAUSE_MS, false);
        } else {
            combo = 0;
            Feedback.wrong();
            state = GS_RESULT;
            replaying = true;
            WatchUi.requestUpdate();
            // Teach: after the wrong-buzz, play the correct answer once.
            _player.play(target, Feedback.WRONG_BUZZ_MS + 500, method(:afterReplay));
        }
    }

    function afterReplay() as Void {
        replaying = false;
        WatchUi.requestUpdate();
        _timer.start(method(:nextItem), WRONG_PAUSE_MS, false);
    }

    function percent() as Number {
        return round == 0 ? 0 : correct * 100 / round;
    }

    hidden function finishSession() as Void {
        if (mode == MODE_LESSON) {
            newBest = Settings.offerBest("L", score);
            if (percent() >= PASS_PERCENT && level == Settings.maxLevel()) {
                leveledUp = Settings.unlockNext();
            }
        } else if (mode == MODE_WORDS) {
            newBest = Settings.offerBest("W", score);
        } else if (mode == MODE_DAILY) {
            var d = today();
            var last = Settings.getNum("dailyDay", -1);
            streak = (last == d - 1) ? Settings.getNum("streak", 0) + 1 : 1;
            Settings.setNum("streak", streak);
            Settings.setNum("dailyDay", d);
            Settings.setNum("dailyScore", score);
            newBest = Settings.offerBest("D", score);
        }
        state = GS_DONE;
        Feedback.done();
        WatchUi.requestUpdate();
    }

    // ---------- input routing ----------

    function onStart() as Void {
        if (state == GS_INTRO) {
            _player.stop();
            _timer.stop();
            nextItem();
        } else if (state == GS_LISTENING) {
            if (letters.size() == 0 && buf.equals("")) { replay(); } else { submit(); }
        } else if (state == GS_DONE && !alreadyDone && mode != MODE_DAILY) {
            start();   // lesson after a level-up starts at the new level
        }
    }

    function stop() as Void {
        _player.stop();
        _timer.stop();
    }

    // Debug builds only: jump to the end of a session with a given score,
    // running the real finishSession() (level unlock, streak, best scores).
    (:debug)
    function debugFinish(pct as Number) as Void {
        stop();
        level = Settings.level();
        pool = Morse.lettersFor(level);
        newChars = Morse.newLettersFor(level);
        total = (mode == MODE_LESSON) ? LESSON_ROUNDS : (mode == MODE_DAILY ? DAILY_ROUNDS : WORD_ROUNDS);
        round = total;
        correct = total * pct / 100;
        bestCombo = correct;
        score = correct * 27;
        finishSession();
    }
}
