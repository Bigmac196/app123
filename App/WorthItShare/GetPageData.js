// Runs in the shared web page before the extension launches. Hands the app the
// resolved URL plus rendered visible text — the fallback for JS-only stores
// (Temu / TikTok Shop) where a raw fetch returns little usable HTML.
var GetPageData = function() {};
GetPageData.prototype = {
    run: function(args) {
        var text = (document.body ? document.body.innerText : "") || "";
        args.completionFunction({
            "url": document.URL,
            "title": document.title,
            "text": text.substring(0, 20000)
        });
    },
    finalize: function(args) {}
};
var ExtensionPreprocessingJS = new GetPageData();
