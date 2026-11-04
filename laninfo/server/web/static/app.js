// laninfo: theme switch, copy buttons, OS tabs, game filter. No dependencies.
(function () {
  "use strict";
  var root = document.documentElement;

  function store(key, val) {
    try {
      if (val === undefined) return localStorage.getItem(key);
      if (val === null) localStorage.removeItem(key); else localStorage.setItem(key, val);
    } catch (e) { return null; }
  }

  // ---------------------------------------------------------- theme
  var themes = ["system", "light", "dark"];
  var toggle = document.getElementById("theme-toggle");
  function applyTheme(t) {
    if (t === "light" || t === "dark") root.setAttribute("data-theme", t); else root.removeAttribute("data-theme");
    if (toggle) toggle.title = "Theme: " + t + " (click to change)";
  }
  applyTheme(store("theme") || "system");
  if (toggle) toggle.addEventListener("click", function () {
    var cur = root.getAttribute("data-theme") || "system";
    var next = themes[(themes.indexOf(cur) + 1) % themes.length];
    store("theme", next === "system" ? null : next);
    applyTheme(next);
  });

  // ---------------------------------------------------------- copy
  // navigator.clipboard needs https; this page runs on plain http in the LAN.
  function copyText(text) {
    if (navigator.clipboard && window.isSecureContext) return navigator.clipboard.writeText(text);
    return new Promise(function (resolve, reject) {
      var ta = document.createElement("textarea");
      ta.value = text;
      ta.setAttribute("readonly", "");
      ta.style.cssText = "position:fixed;top:0;left:0;opacity:0";
      document.body.appendChild(ta);
      ta.select();
      try { document.execCommand("copy") ? resolve() : reject(); } catch (e) { reject(e); }
      document.body.removeChild(ta);
    });
  }
  function flash(btn, msg, ok) {
    btn.setAttribute("data-tip", msg);
    btn.classList.add("tip-on");
    if (ok) btn.classList.add("copied");
    clearTimeout(btn._t);
    btn._t = setTimeout(function () { btn.classList.remove("tip-on", "copied"); }, 1300);
  }
  document.addEventListener("click", function (e) {
    var btn = e.target.closest("[data-copy]");
    if (btn) {
      e.preventDefault();
      copyText(btn.getAttribute("data-copy")).then(
        function () { flash(btn, "Copied", true); },
        function () { flash(btn, "Copy failed", false); });
      return;
    }
    var secret = e.target.closest(".secret");
    if (secret) secret.classList.toggle("revealed");
  });

  var copyIcon = '<svg class="icon" viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><rect x="9" y="9" width="13" height="13" rx="2"/><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"/></svg>';
  document.querySelectorAll(".prose pre").forEach(function (pre) {
    var code = pre.querySelector("code") || pre;
    var btn = document.createElement("button");
    btn.type = "button";
    btn.className = "icon-btn copy-btn pre-copy";
    btn.setAttribute("aria-label", "Copy");
    btn.setAttribute("data-copy", code.textContent.replace(/\n$/, ""));
    btn.innerHTML = copyIcon;
    // wrapper keeps the button in place while the code scrolls sideways
    var wrap = document.createElement("div");
    wrap.className = "pre-wrap";
    pre.parentNode.insertBefore(wrap, pre);
    wrap.appendChild(pre);
    wrap.appendChild(btn);
  });

  // ---------------------------------------------------------- OS tabs
  // Consecutive headings named Windows / Linux / macOS / Steam Deck (same level)
  // become tabs. The choice is remembered and applies to all groups.
  var osRe = /^(windows|linux|macos|mac|steam ?deck|steamos)\b/i;
  function osKey(text) { var m = text.trim().match(osRe); return m ? m[1].toLowerCase().replace(/\s/g, "") : null; }
  function level(el) { var m = /^H([1-6])$/.exec(el.tagName); return m ? +m[1] : 0; }
  function guessOS() {
    var ua = navigator.userAgent;
    if (/Windows/i.test(ua)) return "windows";
    if (/Linux|X11|CrOS/i.test(ua) && !/Android/i.test(ua)) return "linux";
    if (/Mac/i.test(ua)) return "macos";
    return "windows";
  }
  var groups = [];
  document.querySelectorAll(".prose").forEach(function (prose) {
    var kids = Array.prototype.slice.call(prose.children);
    var i = 0;
    while (i < kids.length) {
      var lv = level(kids[i]);
      if (!lv || !osKey(kids[i].textContent)) { i++; continue; }
      var sections = [], j = i;
      while (j < kids.length && level(kids[j]) === lv && osKey(kids[j].textContent)) {
        var sec = { key: osKey(kids[j].textContent), label: kids[j].textContent.trim(), heading: kids[j], nodes: [] };
        j++;
        while (j < kids.length && !(level(kids[j]) && level(kids[j]) <= lv)) { sec.nodes.push(kids[j]); j++; }
        sections.push(sec);
      }
      if (sections.length >= 2) groups.push(build(sections));
      i = j;
    }
  });
  function build(sections) {
    var wrap = document.createElement("div");
    wrap.className = "os-tabs";
    var list = document.createElement("div");
    list.className = "os-tablist";
    list.setAttribute("role", "tablist");
    wrap.appendChild(list);
    sections[0].heading.parentNode.insertBefore(wrap, sections[0].heading);
    var g = { tabs: [], panels: [], keys: [] };
    sections.forEach(function (s) {
      var tab = document.createElement("button");
      tab.type = "button";
      tab.className = "os-tab";
      tab.setAttribute("role", "tab");
      tab.textContent = s.label;
      tab.addEventListener("click", function () { store("os", s.key); selectAll(s.key); });
      list.appendChild(tab);
      var panel = document.createElement("div");
      panel.className = "os-panel";
      panel.setAttribute("role", "tabpanel");
      s.heading.classList.add("os-heading");
      panel.appendChild(s.heading);
      s.nodes.forEach(function (n) { panel.appendChild(n); });
      wrap.appendChild(panel);
      g.tabs.push(tab); g.panels.push(panel); g.keys.push(s.key);
    });
    return g;
  }
  function selectAll(key) {
    groups.forEach(function (g) {
      var idx = g.keys.indexOf(key);
      if (idx < 0) idx = 0;
      g.tabs.forEach(function (t, k) { t.setAttribute("aria-selected", k === idx ? "true" : "false"); });
      g.panels.forEach(function (p, k) { p.hidden = k !== idx; });
    });
  }
  if (groups.length) {
    var want = store("os") || guessOS();
    // a link to a heading inside a tab opens that tab
    if (location.hash) {
      var target = document.getElementById(decodeURIComponent(location.hash.slice(1)));
      var panel = target && target.closest(".os-panel");
      if (panel) groups.forEach(function (g) { var k = g.panels.indexOf(panel); if (k >= 0) want = g.keys[k]; });
    }
    selectAll(want);
  }

  // ---------------------------------------------------------- game filter
  var search = document.getElementById("game-search");
  var grid = document.getElementById("game-grid");
  if (search && grid) {
    var cards = Array.prototype.slice.call(grid.querySelectorAll(".game-card"));
    var empty = document.getElementById("game-empty");
    var segs = Array.prototype.slice.call(document.querySelectorAll(".seg[data-platform]"));
    var platform = "";
    var filter = function () {
      var q = search.value.trim().toLowerCase();
      var shown = 0;
      cards.forEach(function (c) {
        var okQ = !q || q.split(/\s+/).every(function (w) { return (c.getAttribute("data-search") || "").indexOf(w) >= 0; });
        var okP = !platform || ("|" + (c.getAttribute("data-platforms") || "") + "|").indexOf("|" + platform + "|") >= 0;
        c.hidden = !(okQ && okP);
        if (!c.hidden) shown++;
      });
      if (empty) empty.hidden = shown > 0;
    };
    search.addEventListener("input", filter);
    segs.forEach(function (b) {
      b.addEventListener("click", function () {
        platform = b.getAttribute("data-platform");
        segs.forEach(function (x) { x.setAttribute("aria-pressed", x === b ? "true" : "false"); });
        filter();
      });
    });
    document.addEventListener("keydown", function (e) {
      if (e.key === "/" && document.activeElement !== search) { e.preventDefault(); search.focus(); }
    });
  }
})();
