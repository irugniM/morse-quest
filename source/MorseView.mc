import Toybox.Lang;
import Toybox.Graphics;
import Toybox.WatchUi;

// Game screen for all modes.
class MorseView extends WatchUi.View {

    hidden var _g as MorseGame;

    function initialize(game as MorseGame) {
        View.initialize();
        _g = game;
    }

    function onLayout(dc as Graphics.Dc) as Void {
        Ui.init();
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        Ui.clear(dc);
        var g = _g;
        var maxW = dc.getWidth() * 80 / 100;

        if (g.state == GS_INTRO) {
            Ui.pill(dc, 0.16, Graphics.FONT_XTINY, "LEARN");
            Ui.text(dc, 0.42, Graphics.FONT_LARGE, g.target);
            Ui.code(dc, 0.63, Morse.codeFor(g.target), 5, maxW);
            Ui.text(dc, 0.78, Graphics.FONT_XTINY, g.target.equals("") ? "" : (g.introIdx + 1) + " of " + g.newChars.length());
            Ui.text(dc, 0.89, Graphics.FONT_XTINY, "START skip");
            return;
        }

        if (g.state == GS_PLAYING) {
            Ui.text(dc, 0.18, Graphics.FONT_XTINY, header());
            if (g.mode == MODE_TIME) {
                Ui.text(dc, 0.48, Graphics.FONT_SMALL, "buzzing time");
            } else {
                Ui.text(dc, 0.46, Graphics.FONT_MEDIUM, "feel it");
                Ui.text(dc, 0.62, Graphics.FONT_XTINY, g.mode == MODE_LESSON ? "1 letter" : g.target.length() + " letters");
            }
            if (g.mode != MODE_TIME) { Ui.progress(dc, g.round, g.total); }
            return;
        }

        if (g.state == GS_LISTENING) {
            Ui.text(dc, 0.18, Graphics.FONT_XTINY, header());
            var a = g.answer();
            var slots = "";
            if (g.mode != MODE_LESSON) { for (var i = a.length(); i < g.target.length(); i++) { slots += "?"; } }
            Ui.text(dc, 0.40, Graphics.FONT_MEDIUM, a + slots);
            if (!g.buf.equals("")) {
                Ui.code(dc, 0.58, g.buf, 4, maxW);
            } else {
                Ui.text(dc, 0.58, Graphics.FONT_XTINY, "UP dot  DOWN dash");
            }
            Ui.text(dc, 0.74, Graphics.FONT_XTINY,
                (a.equals("") && g.buf.equals("")) ? "START replay" : "START done");
            Ui.progress(dc, g.round, g.total);
            return;
        }

        if (g.state == GS_RESULT) {
            if (g.lastCorrect) {
                Ui.pill(dc, 0.17, Graphics.FONT_SMALL, "+" + g.lastGain);
            } else {
                Ui.pill(dc, 0.17, Graphics.FONT_SMALL, "MISS");
            }
            Ui.text(dc, 0.40, Graphics.FONT_MEDIUM, g.target);
            Ui.code(dc, 0.57, Morse.codesFor(g.target), 4, maxW);
            if (g.lastCorrect) {
                Ui.text(dc, 0.73, Graphics.FONT_XTINY, g.combo >= 2 ? "combo x" + g.combo : "score " + g.score);
            } else {
                var a = g.answer();
                Ui.text(dc, 0.73, Graphics.FONT_XTINY,
                    "you: " + (a.equals("") ? "nothing" : a) + (g.replaying ? "  replay" : ""));
            }
            Ui.progress(dc, g.round, g.total);
            return;
        }

        drawDone(dc, maxW);
    }

    hidden function header() as String {
        var g = _g;
        var name = g.mode == MODE_LESSON ? "Lv " + g.level
            : (g.mode == MODE_DAILY ? "Daily" : (g.mode == MODE_WORDS ? "Words" : "Time"));
        return g.score > 0 ? name + "  " + g.score : name;
    }

    // Done screens share one grid: title pill, big number, two info lines, hint.
    hidden function drawDone(dc as Graphics.Dc, maxW as Number) as Void {
        var g = _g;
        var big = 0.49;
        var l1 = 0.655;
        var l2 = 0.755;
        var hint = 0.855;

        if (g.mode == MODE_TIME) {
            Ui.pill(dc, 0.17, Graphics.FONT_XTINY, "TIME");
            var t = g.timeText;
            var sp = t.find(" ");
            if (sp == null) {
                Ui.text(dc, big, Graphics.FONT_NUMBER_MEDIUM, t);
                Ui.code(dc, l1, Morse.codesFor(t), 4, maxW);
            } else {
                var h = t.substring(0, sp) as String;
                var m = t.substring(sp + 1, t.length()) as String;
                Ui.text(dc, big, Graphics.FONT_NUMBER_MEDIUM, h + ":" + m);
                // Hours and minutes on separate lines so each stays large.
                Ui.code(dc, l1, Morse.codesFor(h), 4, maxW);
                Ui.code(dc, l2, Morse.codesFor(m), 4, maxW);
            }
            Ui.text(dc, hint, Graphics.FONT_XTINY, "START replay");
            return;
        }

        if (g.mode == MODE_DAILY && g.alreadyDone) {
            Ui.pill(dc, 0.17, Graphics.FONT_XTINY, "DONE");
            Ui.text(dc, big, Graphics.FONT_NUMBER_MEDIUM, g.score.toString());
            Ui.text(dc, l1, Graphics.FONT_XTINY, "streak " + days(g.streak));
            Ui.text(dc, l2, Graphics.FONT_XTINY, "new one tomorrow");
            return;
        }

        if (g.mode == MODE_LESSON) {
            Ui.pill(dc, 0.17, Graphics.FONT_XTINY,
                g.leveledUp ? "LV UP!" : (g.newBest ? "BEST!" : "LV " + g.level));
            Ui.text(dc, big, Graphics.FONT_LARGE, g.percent() + "%");
            Ui.text(dc, l1, Graphics.FONT_XTINY, "score " + g.score);
            if (g.leveledUp) {
                Ui.text(dc, l2, Graphics.FONT_XTINY, "new: " + spaced(Morse.newLettersFor(Settings.level())));
            } else if (g.percent() < g.PASS_PERCENT) {
                Ui.text(dc, l2, Graphics.FONT_XTINY, "need " + g.PASS_PERCENT + "% to pass");
            } else {
                Ui.text(dc, l2, Graphics.FONT_XTINY, "best combo " + g.bestCombo);
            }
            Ui.text(dc, hint, Graphics.FONT_XTINY, g.leveledUp ? "START next level" : "START again");
            return;
        }

        // Words / daily
        Ui.pill(dc, 0.17, Graphics.FONT_XTINY,
            g.newBest ? "BEST!" : (g.mode == MODE_DAILY ? "DAILY" : "WORDS"));
        Ui.text(dc, big, Graphics.FONT_NUMBER_MEDIUM, g.score.toString());
        Ui.text(dc, l1, Graphics.FONT_XTINY, g.correct + " of " + g.total + " right");
        if (g.mode == MODE_DAILY) {
            Ui.text(dc, l2, Graphics.FONT_XTINY, "streak " + days(g.streak));
            Ui.text(dc, hint, Graphics.FONT_XTINY, "see you tomorrow");
        } else {
            Ui.text(dc, l2, Graphics.FONT_XTINY, "best combo " + g.bestCombo);
            Ui.text(dc, hint, Graphics.FONT_XTINY, "START again");
        }
    }

    hidden function days(n as Number) as String {
        return n + (n == 1 ? " day" : " days");
    }
    hidden function spaced(s as String) as String {
        var o = "";
        for (var i = 0; i < s.length(); i++) {
            o += (i > 0 ? " " : "") + s.substring(i, i + 1);
        }
        return o;
    }
}
