import Toybox.Lang;
import Toybox.Graphics;
import Toybox.WatchUi;

// Simple paged text screen (help, stats). Each page: [title, line, line, ...].
// UP/DOWN change page, BACK closes.
class PagedView extends WatchUi.View {

    var pages as Array<Array<String> >;
    var page as Number = 0;

    function initialize(p as Array<Array<String> >) {
        View.initialize();
        pages = p;
    }

    function onLayout(dc as Graphics.Dc) as Void {
        Ui.init();
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        Ui.clear(dc);
        var p = pages[page];
        Ui.pill(dc, 0.17, Graphics.FONT_XTINY, p[0]);
        var n = p.size() - 1;
        var top = 0.44;
        var step = 0.125;
        for (var i = 0; i < n; i++) {
            Ui.text(dc, top + step * i, Graphics.FONT_XTINY, p[i + 1]);
        }
        if (pages.size() > 1) {
            drawDots(dc);
        }
    }

    hidden function drawDots(dc as Graphics.Dc) as Void {
        var n = pages.size();
        var gap = 10;
        var x = dc.getWidth() / 2 - (n - 1) * gap / 2;
        var y = Ui.y(dc, 0.91);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        for (var i = 0; i < n; i++) {
            if (i == page) { dc.fillCircle(x + i * gap, y, 3); }
            else { dc.drawCircle(x + i * gap, y, 3); }
        }
    }
}

class PagedDelegate extends WatchUi.BehaviorDelegate {
    hidden var _v as PagedView;

    function initialize(v as PagedView) {
        BehaviorDelegate.initialize();
        _v = v;
    }

    function onNextPage() as Boolean {
        if (_v.page < _v.pages.size() - 1) { _v.page++; WatchUi.requestUpdate(); }
        return true;
    }

    function onPreviousPage() as Boolean {
        if (_v.page > 0) { _v.page--; WatchUi.requestUpdate(); }
        return true;
    }

    function onKeyPressed(evt as WatchUi.KeyEvent) as Boolean {
        if (evt.getKey() == WatchUi.KEY_ENTER) {
            onNextPage();
            return true;
        }
        return false;
    }

    function onSelect() as Boolean { return true; }
}
