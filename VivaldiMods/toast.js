// created with Claude. Account: Milobowler
(function () {
  "use strict";

  // ─── Configuration ────────────────────────────────────────────────────────────
  const CFG = {
    anchorX: "right", // 'left' | 'right' | 'center'
    offsetX: 12, // px from left/right edge
    offsetY: 12, // px from top edge

    height: 29,
    minWidth: 140,
    paddingX: 10,
    fontSize: 11.5,
    iconSize: 14,
    iconGap: 5,
    borderRadius: 16,

    displayMs: 2200,
    fadeMs: 0,

    zIndex: 2147483647,
  };

  // Workspace toast slides in from the top, same anchor as regular toasts
  const WS_CFG = {
    slideMs: 0,
    bounceEasing: "linear",
    retractEasing: "",
  };
  // ──────────────────────────────────────────────────────────────────────────────

  const ICONS = {
    bookmark: `<svg class="vt-icon" viewBox="0 0 16 16" xmlns="http://www.w3.org/2000/svg"><path fill="currentColor" fill-rule="evenodd" d="M11.1425 14.123L8 10.9091L4.8575 14.123C4.54418 14.4434 4 14.2216 4 13.7734V2C4 1.44772 4.44772 1 5 1H11C11.5523 1 12 1.44772 12 2V13.7734C12 14.2216 11.4558 14.4434 11.1425 14.123Z"/></svg>`,
    info: `<svg class="vt-icon" viewBox="0 0 16 16" xmlns="http://www.w3.org/2000/svg"><circle cx="8" cy="8" r="7" stroke="currentColor" stroke-width="1.5" fill="none"/><rect x="7.25" y="6.5" width="1.5" height="5" rx=".75" fill="currentColor"/><circle cx="8" cy="4.5" r=".9" fill="currentColor"/></svg>`,
    success: `<svg class="vt-icon" viewBox="0 0 16 16" xmlns="http://www.w3.org/2000/svg"><polyline points="3,8 6.5,11.5 13,4.5" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" fill="none"/></svg>`,
    error: `<svg class="vt-icon" viewBox="0 0 16 16" xmlns="http://www.w3.org/2000/svg"><line x1="3" y1="3" x2="13" y2="13" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/><line x1="13" y1="3" x2="3" y2="13" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/></svg>`,
    workspace: `<svg class="vt-icon" viewBox="0 0 16 16" xmlns="http://www.w3.org/2000/svg"><rect x="1.5" y="1.5" width="5.5" height="5.5" rx="1.2" fill="currentColor"/><rect x="9" y="1.5" width="5.5" height="5.5" rx="1.2" fill="currentColor"/><rect x="1.5" y="9" width="5.5" height="5.5" rx="1.2" fill="currentColor"/><rect x="9" y="9" width="5.5" height="5.5" rx="1.2" fill="currentColor"/></svg>`,
  };

  // ── Styles ────────────────────────────────────────────────────────────────────
  function ensureStyles() {
    if (document.getElementById("vt-styles")) return;
    const s = document.createElement("style");
    s.id = "vt-styles";

    const anchorRule =
      CFG.anchorX === "right"
        ? `right: ${CFG.offsetX}px !important; left: auto !important;`
        : CFG.anchorX === "left"
          ? `left: ${CFG.offsetX}px !important; right: auto !important;`
          : `left: 50% !important; transform: translateX(-50%) !important;`;

    const alignRule =
      CFG.anchorX === "right"
        ? "flex-end"
        : CFG.anchorX === "center"
          ? "center"
          : "flex-start";

    s.textContent = `
      /* ── Regular toast host ── */
      #vt-host {
        position: fixed !important;
        bottom: auto !important;
        top: ${CFG.offsetY}px !important;
        ${anchorRule}
        display: flex; flex-direction: column; gap: 6px;
        align-items: ${alignRule};
        pointer-events: none;
        z-index: ${CFG.zIndex} !important;
      }

      /* ── Workspace toast host — Aligned to match the Regular host ── */
      #vt-ws-host {
        position: fixed !important;
        /* Matches the top calculation of the regular host */
        bottom: auto !important;
        top: ${CFG.offsetY}px !important;
        ${anchorRule}
        display: flex; flex-direction: column;
        align-items: ${alignRule};
        pointer-events: none;
        z-index: ${CFG.zIndex} !important;
      }

      /* ── Shared toast appearance — No animations ── */
      .vt-toast {
        display: inline-flex;
        align-items: center;
        gap: ${CFG.iconGap}px;
        height: ${CFG.height}px;
        min-width: ${CFG.minWidth}px;
        padding: 0 ${CFG.paddingX}px;
        box-sizing: border-box;
        border-radius: ${CFG.borderRadius}px;
        background: var(--colorBgAlphaBlur, #2e2f37);
        color: var(--colorFg, #bec3cd);
        border: none;
        box-shadow: 0 2px 12px rgba(0,0,0,0.55);
        font-family: var(--sansSerifFont, system-ui, sans-serif);
        font-size: ${CFG.fontSize}px;
        font-weight: 400;
        white-space: nowrap;
        pointer-events: auto;
        cursor: default;
        opacity: 1; /* Always visible immediately */
        line-height: 14.95px;
        letter-spacing: normal;
      }

      /* ── Remove all transitions and transforms ── */
      .vt-toast, .vt-ws-toast, .vt-ws-toast.vt-ws-in, .vt-ws-toast.vt-ws-hiding {
        transition: none !important;
        transform: none !important;
        opacity: 1 !important;
      }

      .vt-hiding, .vt-ws-hiding {
        display: none !important; /* Hide immediately when the class is added */
      }

      .vt-icon {
        width: ${CFG.iconSize}px;
        height: ${CFG.iconSize}px;
        flex-shrink: 0 !important;
        fill: var(--colorFgFaded, rgb(190, 195, 205));
      }
    `;
    (document.head || document.documentElement).appendChild(s);
  }
  // ── Hosts ─────────────────────────────────────────────────────────────────────
  function getHost() {
    let h = document.getElementById("vt-host");
    if (!h) {
      ensureStyles();
      h = document.createElement("div");
      h.id = "vt-host";
      document.body.appendChild(h);
    }
    return h;
  }
  function getWsHost() {
    let h = document.getElementById("vt-ws-host");
    if (!h) {
      ensureStyles();
      h = document.createElement("div");
      h.id = "vt-ws-host";
      document.body.appendChild(h);
    }
    return h;
  }

  // ── Regular toast ─────────────────────────────────────────────────────────────
  function showToast(message, opts) {
    opts = opts || {};
    const host = getHost();
    const toast = document.createElement("div");
    toast.className = "vt-toast";
    const iconKey = opts.icon || "info";
    const iconSvg =
      ICONS[iconKey] ||
      (typeof iconKey === "string" && iconKey.startsWith("<svg")
        ? iconKey
        : ICONS.info);
    toast.innerHTML = iconSvg + "<span>" + message + "</span>";
    host.appendChild(toast);
    function hide() {
      toast.classList.add("vt-hiding");
      setTimeout(() => toast.remove(), CFG.fadeMs + 50);
    }
    const timer = setTimeout(hide, CFG.displayMs);
    toast.addEventListener("click", () => {
      clearTimeout(timer);
      hide();
    });
    return toast;
  }
  window.vivaldiToast = showToast;

  // ── Workspace toast — singleton, updates in-place ─────────────────────────────
  let _wsToast = null;
  let _wsTimer = null;
  let _wsHiding = false;

  function showWorkspaceToast(name) {
    if (_wsToast && !_wsHiding) {
      // Already visible — update text and re-bounce
      _wsToast.querySelector("span").textContent = name;
      _wsToast.classList.remove("vt-ws-in");
      void _wsToast.offsetWidth; // force reflow so transition restarts
      _wsToast.classList.add("vt-ws-in");
      clearTimeout(_wsTimer);
      _wsTimer = setTimeout(_hideWsToast, CFG.displayMs);
      return;
    }

    const host = getWsHost();
    const toast = document.createElement("div");
    toast.className = "vt-toast vt-ws-toast";
    toast.innerHTML = ICONS.workspace + "<span>" + name + "</span>";
    host.appendChild(toast);
    _wsToast = toast;
    _wsHiding = false;

    // Double rAF: paint initial hidden state before transition starts
    requestAnimationFrame(() =>
      requestAnimationFrame(() => {
        if (_wsToast === toast) toast.classList.add("vt-ws-in");
      }),
    );

    _wsTimer = setTimeout(_hideWsToast, CFG.displayMs);
    toast.addEventListener("click", () => {
      clearTimeout(_wsTimer);
      _hideWsToast();
    });
  }

  function _hideWsToast() {
    if (!_wsToast) return;
    _wsHiding = true;
    const toast = _wsToast;
    toast.classList.remove("vt-ws-in");
    toast.classList.add("vt-ws-hiding");
    setTimeout(() => {
      toast.remove();
      if (_wsToast === toast) {
        _wsToast = null;
        _wsHiding = false;
      }
    }, CFG.fadeMs + 50);
  }

  // ── Workspace detection — vivaldi.workspaces.list + chrome.tabs.onActivated ───
  let _wsMap = {}; // id → display name
  let _lastWsId = undefined; // undefined = default workspace

  function buildWsMap(list) {
    _wsMap = {};
    (list || []).forEach(function (ws) {
      _wsMap[ws.id] = ws.name || ws.emoji || ws.icon || "Workspace " + ws.id;
    });
  }

  function wsDisplayName(id) {
    if (id === undefined || id === null) return "Workspace 1";
    return _wsMap[id] || "Workspace " + id;
  }

  function checkTab(tab) {
    if (!tab || !tab.vivExtData) return;
    let ext;
    try {
      ext = JSON.parse(tab.vivExtData);
    } catch (e) {
      return;
    }

    const raw = ext.workspaceId;
    const wsId = raw === undefined || raw === null ? undefined : raw;

    if (wsId === _lastWsId) return; // no change
    _lastWsId = wsId;
    showWorkspaceToast(wsDisplayName(wsId));
  }

  function attachWorkspaceWatcher() {
    // Load workspace name list
    try {
      vivaldi.prefs.get("vivaldi.workspaces.list", function (list) {
        buildWsMap(list);
      });
      vivaldi.prefs.onChanged.addListener(function (change) {
        if (change.path === "vivaldi.workspaces.list") buildWsMap(change.value);
      });
    } catch (e) {
      console.warn("[vivaldiToast] prefs unavailable:", e);
    }

    // Seed current workspace silently — no toast on startup
    chrome.tabs.query({ active: true, currentWindow: true }, function (tabs) {
      if (!tabs || !tabs[0]) return;
      let ext;
      try {
        ext = JSON.parse(tabs[0].vivExtData || "{}");
      } catch (e) {
        return;
      }
      const raw = ext.workspaceId;
      _lastWsId = raw === undefined || raw === null ? undefined : raw;
    });

    // Workspace switches always change the active tab
    chrome.tabs.onActivated.addListener(function (info) {
      chrome.tabs.get(info.tabId, function (tab) {
        checkTab(tab);
      });
    });
  }

  // ── Keyboard + bookmark hooks ─────────────────────────────────────────────────
  function attachIntegrations() {
    if (!document.getElementById("browser"))
      return setTimeout(attachIntegrations, 300);

    try {
      vivaldi.tabsPrivate.onKeyboardShortcut.addListener((id, combo) => {
        if (combo === "Ctrl+Shift+Q")
          showToast("Added bookmark", { icon: "bookmark" });
      });
    } catch (e) {
      console.warn("[vivaldiToast] keyboard hook failed:", e);
    }

    function bindBtns() {
      document
        .querySelectorAll(
          '.BookmarkButton-Button button[title="Bookmark Page"]',
        )
        .forEach((btn) => {
          if (btn.__vtBound) return;
          btn.__vtBound = true;
          btn.addEventListener("click", () =>
            setTimeout(() => {
              showToast(
                btn.classList.contains("button-on")
                  ? "Added bookmark"
                  : "Removed bookmark",
                { icon: "bookmark" },
              );
            }, 80),
          );
        });
    }

    bindBtns();
    new MutationObserver(bindBtns).observe(document.getElementById("browser"), {
      childList: true,
      subtree: true,
    });

    attachWorkspaceWatcher();
  }

  setTimeout(attachIntegrations, 300);
})();
