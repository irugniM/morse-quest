import Toybox.Lang;
import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.System;
import Toybox.Math;

// Drawing helpers shared by all screens. Monochrome-safe: white on black,
// emphasis by inverted "pills" instead of colour. Text that would collide
// with an Instinct-style subscreen is centred in the space to its left.
module Ui {

    const C = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;

    var sub as Graphics.BoundingBox or Null = null;

    function init() as Void {
        if (WatchUi has :getSubscreen) {
            sub = WatchUi.getSubscreen();
        }
    }

    function clear(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
    }

    function y(dc as Graphics.Dc, f as Float) as Number {
        return (dc.getHeight() * f).toNumber();
    }

    // Centre x for a line at yy. Next to the subscreen, centre in the free
    // space between the round bezel (left) and the subscreen.
    // Only moves the line if, centred normally, it would come near the subscreen.
    // SUB_MARGIN leaves room for the physical rim around the subscreen lens,
    // which covers a few pixels more than its reported bounds on the real watch.
    const SUB_MARGIN = 12;

    function cx(dc as Graphics.Dc, yy as Number, halfH as Number, halfW as Number) as Number {
        var s = sub;
        if (s != null && yy - halfH < s.y + s.height + 4 && dc.getWidth() / 2 + halfW > s.x - SUB_MARGIN) {
            var left = 4;
            if (System.getDeviceSettings().screenShape == System.SCREEN_SHAPE_ROUND) {
                var r = dc.getWidth() / 2;
                var dy = (yy - r).abs();
                if (dy < r) {
                    left = r - Math.sqrt(r * r - dy * dy).toNumber() + 4;
                }
            }
            return (left + s.x - SUB_MARGIN) / 2;
        }
        return dc.getWidth() / 2;
    }

    function text(dc as Graphics.Dc, f as Float, font as Graphics.FontType, s as String) as Void {
        var yy = y(dc, f);
        var h = dc.getFontHeight(font) / 2;
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx(dc, yy, h, dc.getTextWidthInPixels(s, font) / 2), yy, font, s, C);
    }

    // Inverted label: white rounded box, black text.
    function pill(dc as Graphics.Dc, f as Float, font as Graphics.FontType, s as String) as Void {
        var yy = y(dc, f);
        var th = dc.getFontHeight(font);
        var tw = dc.getTextWidthInPixels(s, font);
        var w = tw + 12;
        var x = cx(dc, yy, th / 2 + 2, w / 2);
        var h = th + 2;
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(x - w / 2, yy - h / 2, w, h, h / 2);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, yy, font, s, C);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
    }

    // Progress bar near the bottom: done/total.
    function progress(dc as Graphics.Dc, done as Number, total as Number) as Void {
        var w = dc.getWidth() * 50 / 100;
        var x = (dc.getWidth() - w) / 2;
        var yy = y(dc, 0.90);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawRoundedRectangle(x, yy, w, 6, 3);
        if (total > 0 && done > 0) {
            var fw = (w - 2) * done / total;
            if (fw < 4) { fw = 4; }
            dc.fillRoundedRectangle(x + 1, yy + 1, fw, 4, 2);
        }
    }

    // Draws Morse codes graphically: dots as discs, dashes as bars.
    // codes: letters separated by spaces, e.g. "... --- ...".
    // u = base unit in px; shrinks automatically to fit maxW.
    function code(dc as Graphics.Dc, f as Float, codes as String, u as Number, maxW as Number) as Void {
        var w = codeWidth(codes, u);
        while (w > maxW && u > 2) {
            u--;
            w = codeWidth(codes, u);
        }
        var yy = y(dc, f);
        var x = cx(dc, yy, u * 2, w / 2) - w / 2;
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        for (var i = 0; i < codes.length(); i++) {
            var c = codes.substring(i, i + 1) as String;
            if (c.equals(".")) {
                dc.fillCircle(x + u, yy, u);
                x += 2 * u + u;
            } else if (c.equals("-")) {
                dc.fillRoundedRectangle(x, yy - u, 5 * u, 2 * u, u);
                x += 5 * u + u;
            } else if (c.equals(" ")) {
                x += 3 * u;
            } else if (c.equals("/")) {
                x += 3 * u;
            }
        }
    }

    function codeWidth(codes as String, u as Number) as Number {
        var w = 0;
        for (var i = 0; i < codes.length(); i++) {
            var c = codes.substring(i, i + 1) as String;
            if (c.equals(".")) { w += 3 * u; }
            else if (c.equals("-")) { w += 6 * u; }
            else if (c.equals(" ")) { w += 3 * u; }
            else if (c.equals("/")) { w += 3 * u; }
        }
        return w > 0 ? w - u : 0;
    }
}
