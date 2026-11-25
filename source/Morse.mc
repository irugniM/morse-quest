import Toybox.Lang;

// Morse table, learning order, word list and timing.
module Morse {

    // Keep in step with version in manifest.xml (shown under How to play).
    const VERSION = "1.0.3";

    const CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    const CODES = [
        ".-", "-...", "-.-.", "-..", ".", "..-.", "--.", "....", "..", ".---",
        "-.-", ".-..", "--", "-.", "---", ".--.", "--.-", ".-.", "...", "-",
        "..-", "...-", ".--", "-..-", "-.--", "--..",
        "-----", ".----", "..---", "...--", "....-", ".....", "-....", "--...", "---..", "----."
    ];

    // Learning order: E T A N first (simplest), then two new characters per level.
    const ORDER = "ETANIMSORKDUGWHLCPFYBVJXQZ0123456789";
    const FIRST_LEVEL_SIZE = 4;
    const PER_LEVEL = 2;

    const WORDS = [
        "SOS", "RUN", "GPS", "TEA", "ATE", "NET", "TEN", "ANT", "TAN", "EAT",
        "NEAT", "MEAT", "TIME", "NAME", "MAN", "MEN", "SIT", "SAT", "SET", "SEA",
        "SUN", "RAIN", "STAR", "MOON", "ROSE", "DOG", "CAT", "KID", "OK", "GO",
        "NO", "YES", "HI", "RED", "SKY", "WAY", "HOW", "NOW", "ONE", "TWO",
        "MAP", "HELP", "CALL", "HOME", "FOOD", "WORK", "BOOK", "FIRE", "WIND", "WAVE",
        "BLUE", "GOLD", "HEAT", "COLD", "FAST", "SLOW", "JUMP", "QUIZ", "ZONE", "BOX",
        "FIX", "JOB", "VET", "WAX", "ZIP", "AIM", "MIST", "TRAIN", "STORM", "NIGHT",
        "73", "88", "SOS1", "TEST"
    ];

    function maxLevel() as Number {
        return 1 + (ORDER.length() - FIRST_LEVEL_SIZE) / PER_LEVEL;
    }

    // Characters unlocked at a level (1-based).
    function lettersFor(level as Number) as String {
        var n = FIRST_LEVEL_SIZE + (level - 1) * PER_LEVEL;
        if (n > ORDER.length()) { n = ORDER.length(); }
        return ORDER.substring(0, n) as String;
    }

    // Characters introduced at this level.
    function newLettersFor(level as Number) as String {
        if (level <= 1) { return lettersFor(1); }
        var all = lettersFor(level);
        var prev = lettersFor(level - 1);
        return all.substring(prev.length(), all.length()) as String;
    }

    function codeFor(c as String) as String {
        var i = CHARS.find(c);
        return (i == null) ? "" : CODES[i as Number];
    }

    function decode(code as String) as String {
        for (var i = 0; i < CODES.size(); i++) {
            if (CODES[i].equals(code)) {
                return CHARS.substring(i, i + 1) as String;
            }
        }
        return "?";
    }

    // "SOS" -> "... --- ..."
    function codesFor(text as String) as String {
        var out = "";
        for (var i = 0; i < text.length(); i++) {
            var c = text.substring(i, i + 1) as String;
            if (c.equals(" ")) { out += " /"; continue; }
            out += (out.equals("") ? "" : " ") + codeFor(c);
        }
        return out;
    }

    function allIn(word as String, letters as String) as Boolean {
        for (var i = 0; i < word.length(); i++) {
            if (letters.find(word.substring(i, i + 1) as String) == null) { return false; }
        }
        return true;
    }

    function wordsFor(letters as String) as Array<String> {
        var out = [] as Array<String>;
        for (var i = 0; i < WORDS.size(); i++) {
            if (allIn(WORDS[i], letters)) { out.add(WORDS[i]); }
        }
        return out;
    }

    // Vibration plan for a text: list of [onMs, offMs].
    // Character speed is fixed by wpm (dot = 1200/wpm). Gaps between letters and
    // words use a stretched unit (Farnsworth): spacingPct 100 = standard, 200 = double.
    function timing(text as String, wpm as Number, spacingPct as Number) as Array<Array<Number> > {
        var u = 1200 / wpm;
        var fu = u * spacingPct / 100;
        var steps = [] as Array<Array<Number> >;
        for (var i = 0; i < text.length(); i++) {
            var c = text.substring(i, i + 1) as String;
            if (c.equals(" ")) {
                if (steps.size() > 0) { steps[steps.size() - 1][1] = 7 * fu; }
                continue;
            }
            var code = codeFor(c);
            for (var j = 0; j < code.length(); j++) {
                var on = code.substring(j, j + 1).equals(".") ? u : 3 * u;
                var off = (j < code.length() - 1) ? u : 3 * fu;
                steps.add([on, off]);
            }
        }
        if (steps.size() > 0) { steps[steps.size() - 1][1] = 0; }
        return steps;
    }
}
