import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Attention;
import Toybox.System;

// Main menu, settings menu, help and stats pages.
module Menus {

    var main as WatchUi.Menu2 or Null = null;

    // When the main menu was created. The START press that launches the app
    // from the watch's app list can arrive here as a select; ignore selects
    // in the first moment so the app opens on the menu, not in a lesson.
    var openedAt as Number = 0;
    const LAUNCH_GUARD_MS = 800;

    function launchGuardActive() as Boolean {
        return System.getTimer() - openedAt < LAUNCH_GUARD_MS;
    }

    function buildMain() as WatchUi.Menu2 {
        openedAt = System.getTimer();
        var m = new WatchUi.Menu2({:title => "Morse Quest"});
        m.addItem(new WatchUi.MenuItem("Lesson", "", :lesson, null));
        m.addItem(new WatchUi.MenuItem("Words", "", :words, null));
        m.addItem(new WatchUi.MenuItem("Daily cipher", "", :daily, null));
        m.addItem(new WatchUi.MenuItem("Buzz the time", "", :time, null));
        m.addItem(new WatchUi.MenuItem("Stats", "", :stats, null));
        m.addItem(new WatchUi.MenuItem("Settings", "", :settings, null));
        m.addItem(new WatchUi.MenuItem("How to play", "", :help, null));
        addDebugItems(m);
        main = m;
        refreshMain();
        return m;
    }

    function setSub(m as WatchUi.Menu2, id as Symbol, s as String) as Void {
        var i = m.findItemById(id);
        if (i >= 0) {
            var item = m.getItem(i);
            if (item != null) { item.setSubLabel(s); }
        }
    }

    function refreshMain() as Void {
        var m = main;
        if (m == null) { return; }
        var lv = Settings.level();
        setSub(m, :lesson, "Level " + lv + " of " + Morse.maxLevel());
        var bw = Settings.best("W");
        setSub(m, :words, bw > 0 ? "best " + bw : "short words");
        var streak = Settings.getNum("streak", 0);
        var doneToday = Settings.getNum("dailyDay", -1) == MorseGame.today();
        var lastDay = Settings.getNum("dailyDay", -1);
        if (!doneToday && lastDay != MorseGame.today() - 1) { streak = 0; }
        setSub(m, :daily, doneToday ? "done - streak " + streak
            : (streak > 0 ? "ready - streak " + streak : "new every day"));
        setSub(m, :time, "learn by using it");
        setSub(m, :stats, Morse.lettersFor(Settings.maxLevel()).length() + " chars learned");
        setSub(m, :settings, Settings.wpm() + " wpm, " + Settings.spacingLabel());
        setSub(m, :help, "controls and tips");
    }

    // ---------- debug-only test screens (stripped from release builds) ----------

    (:release)
    function addDebugItems(m as WatchUi.Menu2) as Void {
    }

    (:debug)
    function addDebugItems(m as WatchUi.Menu2) as Void {
        m.addItem(new WatchUi.MenuItem("Test screens", "debug only", :debugScreens, null));
    }

    (:debug)
    function showDebugMenu() as Void {
        var m = new WatchUi.Menu2({:title => "Test"});
        m.addItem(new WatchUi.MenuItem("Lesson 95%", "level up", :dLessonPass, null));
        m.addItem(new WatchUi.MenuItem("Lesson 60%", "no level up", :dLessonFail, null));
        m.addItem(new WatchUi.MenuItem("Words 80%", "", :dWords, null));
        m.addItem(new WatchUi.MenuItem("Daily 80%", "finish", :dDaily, null));
        m.addItem(new WatchUi.MenuItem("Daily again", "done today", :dDailyAgain, null));
        m.addItem(new WatchUi.MenuItem("Time", "real playback", :dTime, null));
        m.addItem(new WatchUi.MenuItem("Shot: sample data", "store screenshots", :sData, null));
        m.addItem(new WatchUi.MenuItem("Shot: intro", "", :sIntro, null));
        m.addItem(new WatchUi.MenuItem("Shot: answering", "", :sListen, null));
        m.addItem(new WatchUi.MenuItem("Shot: combo", "", :sRight, null));
        m.addItem(new WatchUi.MenuItem("Shot: miss", "", :sMiss, null));
        m.addItem(new WatchUi.MenuItem("Shot: streak 7", "", :sStreak, null));
        m.addItem(new WatchUi.MenuItem("Streak: yesterday", "1 -> expect 2", :dStreakYesterday, null));
        m.addItem(new WatchUi.MenuItem("Streak: 2 days ago", "5 -> expect 1", :dStreakGap, null));
        WatchUi.pushView(m, new DebugMenuDelegate(), WatchUi.SLIDE_LEFT);
    }

    // Store screenshots: fixed, good-looking states (no timers running).
    (:debug)
    function shot(kind as Symbol) as Void {
        if (kind == :sData) {
            Settings.setNum("maxLevel", 5);
            Settings.setLevel(5);
            Settings.setNum("best_L", 412);
            Settings.setNum("best_W", 260);
            Settings.setNum("best_D", 135);
            Settings.setNum("streak", 6);
            Settings.setNum("dailyDay", MorseGame.today() - 1);
            refreshMain();
            return;
        }
        if (kind == :sStreak) {
            Settings.setNum("dailyDay", MorseGame.today() - 1);
            Settings.setNum("streak", 6);
            debugFinish(MODE_DAILY, 100);
            return;
        }
        var mode = (kind == :sListen || kind == :sMiss) ? MODE_WORDS : MODE_LESSON;
        var g = new MorseGame(mode);
        g.level = 5;
        g.newChars = Morse.newLettersFor(5);
        if (kind == :sIntro) {
            g.target = "K";
            g.introIdx = 1;
            g.state = GS_INTRO;
        } else if (kind == :sListen) {
            g.total = 10; g.round = 3; g.score = 180; g.combo = 3;
            g.target = "SOS";
            g.letters = ["S", "O"] as Array<String>;
            g.buf = "..";
            g.state = GS_LISTENING;
        } else if (kind == :sRight) {
            g.total = 20; g.round = 12; g.score = 412; g.combo = 11;
            g.target = "K"; g.lastCorrect = true; g.lastGain = 30;
            g.state = GS_RESULT;
        } else if (kind == :sMiss) {
            g.total = 10; g.round = 6; g.score = 150;
            g.target = "GPS";
            g.letters = ["G", "P", "E"] as Array<String>;
            g.lastCorrect = false;
            g.state = GS_RESULT;
        }
        WatchUi.pushView(new MorseView(g), new MorseDelegate(g), WatchUi.SLIDE_IMMEDIATE);
    }

    (:debug)
    function debugFinish(mode as GameMode, pct as Number) as Void {
        var g = new MorseGame(mode);
        WatchUi.pushView(new MorseView(g), new MorseDelegate(g), WatchUi.SLIDE_LEFT);
        g.debugFinish(pct);
    }

    function startGame(mode as GameMode) as Void {
        var g = new MorseGame(mode);
        WatchUi.pushView(new MorseView(g), new MorseDelegate(g), WatchUi.SLIDE_LEFT);
        g.start();
    }

    // ---------- settings ----------

    function buildSettings() as WatchUi.Menu2 {
        var m = new WatchUi.Menu2({:title => "Settings"});
        m.addItem(new WatchUi.MenuItem("Letter speed", "", :speed, null));
        m.addItem(new WatchUi.MenuItem("Letter spacing", "", :spacing, null));
        m.addItem(new WatchUi.MenuItem("Vibration", "", :vibe, null));
        m.addItem(new WatchUi.MenuItem("Sound", "", :sound, null));
        m.addItem(new WatchUi.MenuItem("Lesson level", "", :level, null));
        m.addItem(new WatchUi.MenuItem("Reset progress", "levels, scores, stats", :reset, null));
        refreshSettings(m);
        return m;
    }

    function refreshSettings(m as WatchUi.Menu2) as Void {
        setSub(m, :speed, Settings.wpm() + " wpm");
        setSub(m, :spacing, Settings.spacingLabel());
        setSub(m, :vibe, Settings.vibe() + "%");
        setSub(m, :sound, Settings.soundLabel());
        setSub(m, :level, Settings.level() + " of " + Settings.maxLevel() + " unlocked");
    }

    // ---------- pages ----------

    function helpPages() as Array<Array<String> > {
        return [
            ["HOW", "Watch buzzes a", "letter in Morse.", "Tap it back", "eyes-free."],
            ["KEYS", "UP = dot", "DOWN = dash", "pause = next", "START = done"],
            ["LEVELS", "Start: E T A N", "90% unlocks", "2 more letters.", "Misses repeat."],
            ["SPACING", "Letters keep", "their speed.", "Gaps give time", "to think."],
            ["SCORE", "10 per letter", "combo up to x3", "+5 quick start", "Daily = streak"]
        ] as Array<Array<String> >;
    }

    function statsPages() as Array<Array<String> > {
        var maxL = Settings.maxLevel();
        var learned = Morse.lettersFor(maxL);
        var p1 = ["LEVEL",
            "level " + maxL + " of " + Morse.maxLevel(),
            learned.length() + " of " + Morse.ORDER.length() + " chars",
            "streak " + Settings.getNum("streak", 0) + " days"] as Array<String>;
        var p2 = ["BEST",
            "lesson " + Settings.best("L"),
            "words " + Settings.best("W"),
            "daily " + Settings.best("D")] as Array<String>;

        // Weakest characters (>= 5 tries), worst first.
        var weak = [] as Array<String>;
        var rates = [] as Array<Number>;
        for (var i = 0; i < learned.length(); i++) {
            var c = learned.substring(i, i + 1) as String;
            var e = Settings.errorRate(c);
            if (e > 0) {
                var j = 0;
                while (j < rates.size() && rates[j] >= e) { j++; }
                weak = insertAt(weak, j, c + "  " + (100 - e) + "% right") as Array<String>;
                rates = insertAt(rates, j, e) as Array<Number>;
            }
        }
        var p3 = ["WEAK"] as Array<String>;
        if (weak.size() == 0) {
            p3.add("no weak letters yet");
            p3.add("(5+ tries each)");
        } else {
            for (var k = 0; k < weak.size() && k < 4; k++) { p3.add(weak[k]); }
        }
        return [p1, p2, p3] as Array<Array<String> >;
    }

    function insertAt(a as Array, i as Number, v as Object) as Array {
        var out = [];
        for (var k = 0; k < a.size(); k++) {
            if (k == i) { out.add(v); }
            out.add(a[k]);
        }
        if (i >= a.size()) { out.add(v); }
        return out;
    }

    function showPages(pages as Array<Array<String> >) as Void {
        var v = new PagedView(pages);
        WatchUi.pushView(v, new PagedDelegate(v), WatchUi.SLIDE_LEFT);
    }
}

class MainMenuDelegate extends WatchUi.Menu2InputDelegate {

    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        if (Menus.launchGuardActive()) { return; }
        var id = item.getId();
        if (id == :lesson) { Menus.startGame(MODE_LESSON); }
        else if (id == :words) { Menus.startGame(MODE_WORDS); }
        else if (id == :daily) { Menus.startGame(MODE_DAILY); }
        else if (id == :time) { Menus.startGame(MODE_TIME); }
        else if (id == :stats) { Menus.showPages(Menus.statsPages()); }
        else if (id == :help) { Menus.showPages(Menus.helpPages()); }
        else if (id == :debugScreens) { openDebug(); }
        else if (id == :settings) {
            var m = Menus.buildSettings();
            WatchUi.pushView(m, new SettingsMenuDelegate(m), WatchUi.SLIDE_LEFT);
        }
    }

    function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }

    (:release)
    hidden function openDebug() as Void {
    }

    (:debug)
    hidden function openDebug() as Void {
        Menus.showDebugMenu();
    }
}

(:debug)
class DebugMenuDelegate extends WatchUi.Menu2InputDelegate {

    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        if (id == :dLessonPass) { Menus.debugFinish(MODE_LESSON, 95); }
        else if (id == :dLessonFail) { Menus.debugFinish(MODE_LESSON, 60); }
        else if (id == :dWords) { Menus.debugFinish(MODE_WORDS, 80); }
        else if (id == :dDaily) { Menus.debugFinish(MODE_DAILY, 80); }
        else if (id == :dDailyAgain) { Menus.startGame(MODE_DAILY); }
        else if (id == :dTime) { Menus.startGame(MODE_TIME); }
        else if (id == :sData || id == :sIntro || id == :sListen || id == :sRight
            || id == :sMiss || id == :sStreak) { Menus.shot(id as Symbol); }
        else if (id == :dStreakYesterday || id == :dStreakGap) {
            // Pretend the last daily was played 1 (or 2) days ago, then run the
            // real daily finish, which decides whether the streak continues.
            var back = (id == :dStreakYesterday) ? 1 : 2;
            Settings.setNum("dailyDay", MorseGame.today() - back);
            Settings.setNum("streak", back == 1 ? 1 : 5);
            Menus.refreshMain();
            Menus.debugFinish(MODE_DAILY, 80);
        }
    }
}

class SettingsMenuDelegate extends WatchUi.Menu2InputDelegate {

    hidden var _m as WatchUi.Menu2;

    function initialize(m as WatchUi.Menu2) {
        Menu2InputDelegate.initialize();
        _m = m;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        if (id == :speed) {
            Settings.cycleSpeed();
        } else if (id == :spacing) {
            Settings.cycleSpacing();
        } else if (id == :vibe) {
            Settings.cycleVibe();
            Feedback.vibe(Settings.vibe(), 400);   // feel the new strength
        } else if (id == :sound) {
            Settings.cycleSound();
            if (Settings.sound() == 2) { Feedback.symbol(300); }
            else { Feedback.tone(Attention.TONE_KEY); }
        } else if (id == :level) {
            Settings.cycleLevel();
        } else if (id == :reset) {
            WatchUi.pushView(new WatchUi.Confirmation("Reset all progress?"),
                new ResetConfirmDelegate(_m), WatchUi.SLIDE_IMMEDIATE);
            return;
        }
        Menus.refreshSettings(_m);
        WatchUi.requestUpdate();
    }

    function onBack() as Void {
        Menus.refreshMain();
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }
}

// First launch: ask whether to play sounds. A Menu2 is used instead of a
// Confirmation because the native confirmation centres its question at the
// top of the screen, where the Instinct subscreen covers it.
class SoundPromptDelegate extends WatchUi.Menu2InputDelegate {

    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        choose(item.getId() == :soundOn ? 1 : 0);
    }

    // BACK keeps the default (sound on) and doesn't ask again.
    function onBack() as Void {
        choose(Settings.sound());
    }

    hidden function choose(mode as Number) as Void {
        Settings.setNum("sound", mode);
        Settings.setNum("soundAsked", 1);
        if (mode == 1) { Feedback.tone(Attention.TONE_KEY); }
        Menus.refreshMain();
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}

class ResetConfirmDelegate extends WatchUi.ConfirmationDelegate {
    hidden var _m as WatchUi.Menu2;

    function initialize(m as WatchUi.Menu2) {
        ConfirmationDelegate.initialize();
        _m = m;
    }

    function onResponse(response as WatchUi.Confirm) as Boolean {
        if (response == WatchUi.CONFIRM_YES) {
            Settings.resetAll();
            Menus.refreshSettings(_m);
            Menus.refreshMain();
        }
        return true;
    }
}
