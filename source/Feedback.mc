import Toybox.Lang;
import Toybox.Attention;

// Vibration and sound, respecting settings and device capabilities.
module Feedback {

    const MORSE_TONE_HZ = 700;
    const WRONG_BUZZ_MS = 1000;   // clearly longer than any dash
    const WRONG_BUZZ_DUTY = 30;

    function vibe(duty as Number, ms as Number) as Void {
        if (Attention has :vibrate) {
            Attention.vibrate([new Attention.VibeProfile(duty, ms)]);
        }
    }

    // One Morse symbol: vibration, plus a beep if sound = morse.
    function symbol(ms as Number) as Void {
        vibe(Settings.vibe(), ms);
        if (Settings.sound() == 2 && Attention has :ToneProfile) {
            Attention.playTone({:toneProfile => [new Attention.ToneProfile(MORSE_TONE_HZ, ms)]});
        }
    }

    function tone(t as Attention.Tone) as Void {
        if (Settings.sound() >= 1 && Attention has :playTone) {
            Attention.playTone(t);
        }
    }

    function right() as Void {
        tone(Attention.TONE_SUCCESS);
    }

    function wrong() as Void {
        tone(Attention.TONE_FAILURE);
        vibe(WRONG_BUZZ_DUTY, WRONG_BUZZ_MS);
    }

    function done() as Void {
        tone(Attention.TONE_SUCCESS);
        vibe(Settings.vibe(), 150);
    }
}
