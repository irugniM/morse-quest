import Toybox.Lang;
import Toybox.Application;

// Persistent settings and progress (Application.Storage).
module Settings {

    const SPEEDS = [8, 10, 12, 15];                 // character WPM
    const SPACINGS = [100, 150, 200, 300];           // Farnsworth gap stretch, %
    const SPACING_LABELS = ["normal", "wide", "wider", "widest"];
    const VIBES = [100, 70, 40];
    const SOUND_LABELS = ["off", "beep", "morse"];   // morse = beep along with vibration

    function getNum(key as String, dflt as Number) as Number {
        var v = Application.Storage.getValue(key);
        return (v instanceof Number) ? v : dflt;
    }

    function setNum(key as String, v as Number) as Void {
        Application.Storage.setValue(key, v);
    }

    function idx(key as String, dflt as Number, n as Number) as Number {
        var v = getNum(key, dflt);
        return (v >= 0 && v < n) ? v : dflt;
    }

    function cycle(key as String, dflt as Number, n as Number) as Void {
        setNum(key, (idx(key, dflt, n) + 1) % n);
    }

    function wpm() as Number { return SPEEDS[idx("speed", 0, SPEEDS.size())]; }
    function cycleSpeed() as Void { cycle("speed", 0, SPEEDS.size()); }

    // Default "wider" so beginners get time between letters (Farnsworth).
    function spacing() as Number { return SPACINGS[idx("spacing", 2, SPACINGS.size())]; }
    function spacingLabel() as String { return SPACING_LABELS[idx("spacing", 2, SPACINGS.size())]; }
    function cycleSpacing() as Void { cycle("spacing", 2, SPACINGS.size()); }

    function vibe() as Number { return VIBES[idx("vibe", 0, VIBES.size())]; }
    function cycleVibe() as Void { cycle("vibe", 0, VIBES.size()); }

    function sound() as Number { return idx("sound", 1, SOUND_LABELS.size()); }
    function soundLabel() as String { return SOUND_LABELS[sound()]; }
    function cycleSound() as Void { cycle("sound", 1, SOUND_LABELS.size()); }

    // Highest unlocked level, and the level lessons are played at.
    function maxLevel() as Number { return getNum("maxLevel", 1); }
    function level() as Number {
        var l = getNum("level", 1);
        return (l < 1 || l > maxLevel()) ? maxLevel() : l;
    }
    function setLevel(l as Number) as Void { setNum("level", l); }
    function cycleLevel() as Void {
        var l = level() + 1;
        setLevel(l > maxLevel() ? 1 : l);
    }
    function unlockNext() as Boolean {
        if (maxLevel() >= Morse.maxLevel()) { return false; }
        setNum("maxLevel", maxLevel() + 1);
        setLevel(maxLevel());
        return true;
    }

    function best(mode as String) as Number { return getNum("best_" + mode, 0); }
    function offerBest(mode as String, score as Number) as Boolean {
        if (score > best(mode)) { setNum("best_" + mode, score); return true; }
        return false;
    }

    // Per-character [tries, correct], used for stats and to drill weak letters.
    function letterStats() as Dictionary {
        var d = Application.Storage.getValue("letters");
        return (d instanceof Dictionary) ? d : {};
    }

    function recordLetter(c as String, ok as Boolean) as Void {
        var d = letterStats();
        var s = d.get(c);
        var a = (s instanceof Array) ? s : [0, 0];
        a[0] = (a[0] as Number) + 1;
        if (ok) { a[1] = (a[1] as Number) + 1; }
        d.put(c, a);
        Application.Storage.setValue("letters", d);
    }

    // 0..100 error rate, or -1 if fewer than 5 tries.
    function errorRate(c as String) as Number {
        var s = letterStats().get(c);
        if (!(s instanceof Array) || (s[0] as Number) < 5) { return -1; }
        var n = s[0] as Number;
        return (n - (s[1] as Number)) * 100 / n;
    }

    // Clears progress (levels, scores, streak, letter stats) but keeps the
    // player's settings and the answer to the first-launch sound question.
    const KEEP_KEYS = ["speed", "spacing", "vibe", "sound", "soundAsked"];

    function resetAll() as Void {
        var kept = {};
        for (var i = 0; i < KEEP_KEYS.size(); i++) {
            var v = Application.Storage.getValue(KEEP_KEYS[i]);
            if (v != null) { kept.put(KEEP_KEYS[i], v); }
        }
        Application.Storage.clearValues();
        var keys = kept.keys();
        for (var i = 0; i < keys.size(); i++) {
            Application.Storage.setValue(keys[i] as String, kept.get(keys[i]) as Application.PropertyValueType);
        }
    }
}
