if (is_nav6up) {
    var ss = document.styleSheets[0];
    var i = 0;
    var size = '8.5pt';
    var height = '12pt';
    var smSize = '7pt';
    var lgSize = '10pt';
    var lgHeight = '13pt';
    if (is_unix) {
        size = '10pt';
        height = '16pt';
        smSize = '8.5pt';
        lgSize = '12pt';
        lgHeight = '17pt';
    }

    ss.insertRule("body { background:white; font-family:Verdana,Helvetica,Arial,sans-serif; }", i++);
    ss.insertRule(".tab { background:#006666; color:white; font-weight:bold; font-size:" + lgSize + "; }", i++);
    ss.insertRule(".light { background:#cccc99; font-size:" + smSize + "; }", i++);
    ss.insertRule(".context { background:#999966; font-size:" + smSize + "; }", i++);
    ss.insertRule("h3 { font-size:" + lgSize + "; line-height:" + lgHeight + "; }", i++);
    ss.insertRule("p { font-size:" + size + "; line-height:" + height + "; }", i++);
    ss.insertRule(".redLink { color:#993300; }", i++);
    ss.insertRule(".blackLink { color:#000000; }", i++);
    ss.insertRule("td { font-size:" + size + "; line-height:" + height + "; }", i++);
    ss.insertRule("dt {  font-size:" + size + "; line-height:" + lgHeight + "; font-weight:bold; }", i++);
    ss.insertRule("dd { font-size:" + size + "; line-height:" + height + "; }", i++);
    ss.insertRule("li { font-size:" + size + "; line-height:" + height + "; }", i++);
} else if (is_nav4up) {
    var ss = document.classes;
    var tags = document.tags;
    var size = '11pt';
    var height = '16pt';
    var smSize = '10pt';
    var lgSize = '12pt';
    var lgHeight = '16pt';
    if (is_win) {
        size = '9pt';
        height = '13pt';
        smSize = '8pt';
        lgSize = '10pt';
        lgHeight = '13pt';
    }

    tags.body.backgroundColor = 'white';

    tags.p.fontFamily = 'Verdana,Helvetica,Arial,sans-serif';
    tags.p.fontSize = size;
    tags.p.lineHeight = height;

    tags.td.fontFamily = 'Verdana,Helvetica,Arial,sans-serif';
    tags.td.fontSize = size;

    tags.h3.fontFamily = 'Verdana,Helvetica,Arial,sans-serif';
    tags.h3.fontSize = lgSize;
    tags.h3.fontWeight = 'bold';
    tags.h3.lineHeight = lgHeight;

    tags.dl.fontFamily = 'Verdana,Helvetica,Arial,sans-serif';
    tags.dl.fontSize = size;
    tags.dl.lineHeight = height;
    tags.dt.fontWeight = 'bold';

    tags.ul.fontFamily = 'Verdana,Helvetica,Arial,sans-serif';
    tags.ul.fontSize = size;
    tags.ul.lineHeight = height;

    ss.tab.all.fontFamily = 'Verdana,Helvetica,Arial,sans-serif';
    ss.tab.all.fontWeight = 'bold';
    ss.tab.all.fontSize = lgSize;
    ss.tab.all.backgroundColor = '#006666';
    ss.tab.all.color = 'white';

    ss.light.all.fontFamily = 'Verdana,Helvetica,Arial,sans-serif';
    ss.light.all.fontSize = smSize;
    ss.light.all.backgroundColor = '#cccc99';

    ss.redLink.all.color = '#993300';
    ss.blackLink.all.color = '#000000';

    ss.context.all.fontFamily = 'Verdana,Helvetica,Arial,sans-serif';
    ss.context.all.fontSize = smSize;
    ss.context.all.backgroundColor = '#999966';
} else if (is_ie) {
    var ss = document.styleSheets[0];
    if (is_win) {
        var i = 0;
        ss.addRule("body", "background:white; font-family:Verdana,Helvetica,Arial,sans-serif;", i++);
        ss.addRule(".light", "background:#cccc99; font-size:7pt;", i++);
        ss.addRule(".tab", "background:#006666; color:white; font-weight:bold; font-size:10pt;", i++);
        ss.addRule(".context", "background:#999966; font-size:7.25pt; line-height:9pt;", i++);
        ss.addRule(".redLink", "color:#993300;", i++);
        ss.addRule(".blackLink", "color:#000000;", i++);
        ss.addRule("h3", "font-size:10pt; line-height:12pt;", i++);
        ss.addRule("p", "font-size:8pt; line-height:11pt;", i++);
        ss.addRule("dt", " font-size:8pt; line-height:11pt; font-weight:bold;", i++);
        ss.addRule("dd", "font-size:8pt; line-height:11pt;", i++);
        ss.addRule("li", "font-size:8pt; line-height:11pt;", i++);
    } else if (is_mac) {
        ss.addRule("body", "background:white; font-family:Verdana,Helvetica,Arial,sans-serif;");
        ss.addRule(".tab", "background:#006666; color:white; font-weight:bold; font-size:10pt;");
        ss.addRule(".light", "background:#cccc99; font-size:7pt;");
        ss.addRule(".context", "background:#999966; font-size:7.5pt; line-height:10.5pt;");
        ss.addRule(".redLink", "color:#993300;");
        ss.addRule(".blackLink", "color:#000000;");
        ss.addRule("h3", "font-size:10pt; line-height:13pt;");
        ss.addRule("p", "font-size:8pt; line-height:11.5pt;");
        ss.addRule("dt", " font-size:8pt; line-height:11.5pt; font-weight:bold;");
        ss.addRule("dd", "font-size:8pt; line-height:11.5pt;");
        ss.addRule("li", "font-size:8pt; line-height:11.5pt;");
    }
} else {
    // It's something else.
}
