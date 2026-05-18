// =============================================================================
// Auto-Hibernate Web Panels  v2.0
//
// Problem:
//   Web panels in Vivaldi stay alive in the background indefinitely, consuming
//   RAM and CPU even when they are hidden and not in use.
//
// Motivation:
//   Web Panels are the main reason why I use the Vivaldi browser. This feature
//   changed my browsing experience and improved it a lot. However, web panel
//   tabs do not have proper hibernation, and they can use a lot of system resources.
//   I hope I am not the only one who has this problem, which is why I am sharing this mod here.
//
// Solution:
//   This mod automatically hibernates each web panel after it has been hidden for
//   a configurable amount of time, using the native chrome.tabs.discard() API.
//   Tabs with active audio playing are not hibernated. Vivaldi restores the panel
//   automatically when the user opens it again, preserving the session state.
//   There is also a toggle button on each web panel tab that allows you to enable
//   or disable auto-hibernation for that panel individually.
//
// Features:
//   • Per-panel toggle button in the panel header (enable / disable per site)
//   • Hibernate preference is persisted per origin via chrome.storage.local
//   • Media guard — hibernation is skipped while audio is playing
//   • Media poll — periodically re-checks for media while the panel is hidden
// =============================================================================

(function () {
  "use strict";

  // ── Configuration ─────────────────────────────────────────────────────────────

  // Time (minutes) after which an inactive panel tab is hibernated.
  // A panel is considered inactive when it is hidden and no media is playing.
  const HIBERNATE_DELAY_MS = 5 * 60 * 1000; // 5 minutes
  // Interval (seconds) at which a hidden panel tab is checked for active
  // media (audio or video). Prevents hibernation while something is playing.
  const MEDIA_POLL_INTERVAL_MS = 30 * 1000; // 30 seconds
  const STORAGE_PREFIX = "autoHibernate:";

  // ── Logging ──────────────────────────────────────────────────────────────────
  // Retained at warn/error level for fast diagnosis. Remove or set LOG_LEVEL
  // to 'none' to silence completely.
  const LOG_LEVEL = "warn"; // 'warn' | 'none'
  const L = {
    _c: "color:#7c9;font-weight:bold",
    _t: (t) => `%c[hib:${t}]`,
    warn: (t, ...a) =>
      LOG_LEVEL !== "none" && console.warn(L._t(t), L._c, ...a),
    error: (t, ...a) =>
      LOG_LEVEL !== "none" && console.error(L._t(t), L._c, ...a),
  };

  // ── State ─────────────────────────────────────────────────────────────────────
  const hibernateTimers = new Map(); // uuid -> timeoutId
  const mediaPolls = new Map(); // uuid -> intervalId
  const isPlayingMedia = new Map(); // uuid -> boolean
  const hibernateEnabled = new Map(); // uuid -> boolean
  const storageLoaded = new Set(); // uuid
  const indexToUUID = new Map(); // panelIndex -> uuid
  const uuidSrcMap = new Map(); // uuid -> last known src

  let _initialized = false;

  // ── DOM helpers ───────────────────────────────────────────────────────────────
  const getLivePanels = () =>
    Array.from(document.querySelectorAll("#panels .panel.webpanel"));
  const isLivePanel = (panel) =>
    !!document.querySelector("#panels")?.contains(panel);
  const isPanelVisible = (panel) => panel.classList.contains("visible");
  const getWebview = (panel) =>
    panel.querySelector(".webpanel-content webview");

  function findLivePanelByUUID(uuid) {
    return getLivePanels().find((p) => p.__hibUUID === uuid) || null;
  }

  function getBestSrc(wv, uuid) {
    if (wv) {
      try {
        const live = typeof wv.getURL === "function" ? wv.getURL() : "";
        if (live && live !== "about:blank") return live;
      } catch (_) {}
      const fromWv = wv.__lastSrc || wv.getAttribute("src") || "";
      if (fromWv && fromWv !== "about:blank") return fromWv;
    }
    if (uuid && uuidSrcMap.has(uuid)) return uuidSrcMap.get(uuid);
    return "";
  }

  function getOrigin(src) {
    try {
      return src && src !== "about:blank" ? new URL(src).origin : null;
    } catch (_) {
      return null;
    }
  }

  // ── UUID resolution ───────────────────────────────────────────────────────────
  function getWebpanelButtons() {
    return Array.from(
      document.querySelectorAll(
        '.button-toolbar-webpanel button[data-name^="WEBPANEL_"]',
      ),
    );
  }

  function resolveUUIDByURL(src) {
    if (!src || src === "about:blank") return null;
    let srcOrigin;
    try {
      srcOrigin = new URL(src).origin;
    } catch (_) {
      return null;
    }

    for (const btn of getWebpanelButtons()) {
      const uuid = btn.getAttribute("data-name");
      if (!uuid) continue;
      const urlLine =
        (btn.getAttribute("title") || "")
          .split("\n")
          .find((l) => l.startsWith("http")) || "";
      try {
        if (urlLine && new URL(urlLine).origin === srcOrigin) return uuid;
      } catch (_) {}
    }
    return null;
  }

  function resolveUUIDByIndex(panelIndex) {
    const btn = getWebpanelButtons()[panelIndex];
    return btn ? btn.getAttribute("data-name") : null;
  }

  function getUUID(panel) {
    if (panel.__hibUUID) return panel.__hibUUID;

    const idx = getLivePanels().indexOf(panel);
    const wv = getWebview(panel);
    const src = getBestSrc(wv);
    const byURL = resolveUUIDByURL(src);

    if (byURL) {
      panel.__hibUUID = byURL;
      return byURL;
    }
    if (indexToUUID.has(idx)) {
      panel.__hibUUID = indexToUUID.get(idx);
      return panel.__hibUUID;
    }

    const byIdx = resolveUUIDByIndex(idx);
    if (byIdx) {
      panel.__hibUUID = byIdx;
      return byIdx;
    }

    L.warn("uuid:FAIL", "idx=", idx, "src=", src);
    return null;
  }

  // ── Storage ───────────────────────────────────────────────────────────────────
  const skey = (uuid) => STORAGE_PREFIX + uuid;

  function saveState(uuid, disabled) {
    if (!uuid) return;
    try {
      chrome.storage.local.set({ [skey(uuid)]: Boolean(disabled) }, () => {
        if (chrome.runtime.lastError)
          L.error("storage:save", chrome.runtime.lastError.message);
      });
    } catch (e) {
      L.error("storage:save:throw", e?.message || e);
    }
  }

  function loadState(uuid, cb) {
    if (!uuid) {
      cb(false);
      return;
    }
    try {
      chrome.storage.local.get(skey(uuid), (data) =>
        cb(!!(data && data[skey(uuid)])),
      );
    } catch (e) {
      L.error("storage:load:throw", e?.message || e);
      cb(false);
    }
  }

  // ── Toggle button ─────────────────────────────────────────────────────────────
  const ICON_ON =
    '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="currentColor">' +
    '<path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"/></svg>';

  const ICON_OFF =
    '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none"' +
    ' stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">' +
    '<circle cx="12" cy="12" r="5"/>' +
    '<line x1="12" y1="1" x2="12" y2="3"/><line x1="12" y1="21" x2="12" y2="23"/>' +
    '<line x1="4.22" y1="4.22" x2="5.64" y2="5.64"/><line x1="18.36" y1="18.36" x2="19.78" y2="19.78"/>' +
    '<line x1="1" y1="12" x2="3" y2="12"/><line x1="21" y1="12" x2="23" y2="12"/>' +
    '<line x1="4.22" y1="19.78" x2="5.64" y2="18.36"/><line x1="18.36" y1="5.64" x2="19.78" y2="4.22"/></svg>';

  function syncBtn(btn, enabled) {
    btn.innerHTML = enabled ? ICON_ON : ICON_OFF;
    btn.title = enabled
      ? "Auto-hibernate: ON — click to disable"
      : "Auto-hibernate: OFF — click to enable";
    btn.style.opacity = enabled ? "1" : "0.4";
  }

  function getHeaderGroup(panel) {
    const h = Array.from(panel.children).find(
      (el) =>
        el.tagName === "HEADER" && el.classList.contains("webpanel-header"),
    );
    if (!h) return null;
    const t = Array.from(h.children).find(
      (el) =>
        el.classList.contains("toolbar-default") &&
        el.classList.contains("full-width"),
    );
    if (!t) return null;
    return (
      Array.from(t.children).find(
        (el) =>
          el.classList.contains("toolbar") &&
          el.classList.contains("toolbar-group"),
      ) || null
    );
  }

  function addToggleToHeader(panel) {
    const uuid = getUUID(panel);
    if (!uuid || !uuid.startsWith("WEBPANEL_") || !storageLoaded.has(uuid))
      return;

    panel
      .querySelectorAll(".mod-auto-hibernate-toggle")
      .forEach((el) => el.remove());
    const group = getHeaderGroup(panel);
    if (!group) return;

    const wrap = document.createElement("div");
    wrap.className = "button-toolbar mod-auto-hibernate-toggle";

    const btn = document.createElement("button");
    btn.className = "ToolbarButton-Button";
    btn.style.cssText =
      "display:flex;align-items:center;justify-content:center;";
    syncBtn(btn, hibernateEnabled.get(uuid) !== false);

    btn.addEventListener("click", () => {
      const next = !(hibernateEnabled.get(uuid) !== false);
      hibernateEnabled.set(uuid, next);
      syncBtn(btn, next);
      saveState(uuid, !next);

      if (!next) {
        cancelHibernation(uuid);
        stopMediaPoll(uuid);
      } else if (!isPanelVisible(panel)) {
        scheduleHibernation(uuid);
        startMediaPoll(panel, uuid);
      }
    });

    wrap.appendChild(btn);
    const padRight = Array.from(group.children).find(
      (el) =>
        el.classList.contains("toolbar-group") &&
        el.classList.contains("pad-right"),
    );
    if (padRight) padRight.insertAdjacentElement("afterend", wrap);
    else group.insertBefore(wrap, group.firstChild);
  }

  // ── State preload ─────────────────────────────────────────────────────────────
  function withState(panel, cb) {
    const uuid = getUUID(panel);
    if (!uuid) {
      L.warn("withState:noUUID");
      return;
    }

    if (storageLoaded.has(uuid)) {
      cb(uuid);
      return;
    }

    storageLoaded.add(uuid);
    loadState(uuid, (wasDisabled) => {
      hibernateEnabled.set(uuid, !wasDisabled);
      cb(uuid);
    });
  }

  // ── Media detection ───────────────────────────────────────────────────────────
  function checkMedia(panel, cb) {
    if (!isLivePanel(panel)) {
      cb(false);
      return;
    }
    const wv = getWebview(panel);
    if (!wv) {
      cb(false);
      return;
    }
    if (wv.hasAttribute("audio")) {
      cb(true);
      return;
    }

    try {
      wv.executeScript(
        {
          code: `(function(){return[...document.querySelectorAll('audio,video')].some(e=>!e.paused&&e.duration>0)})()`,
        },
        (r) => cb(!!(r && r[0] === true)),
      );
    } catch (e) {
      L.error("media:executeScript", e?.message || e);
      cb(false);
    }
  }

  // ── Discard ───────────────────────────────────────────────────────────────────
  function discardTab(src, uuid) {
    if (!src || src === "about:blank") return;

    chrome.tabs.query({}, (tabs) => {
      if (chrome.runtime.lastError) {
        L.error("discard:query", chrome.runtime.lastError);
        return;
      }

      const origin = getOrigin(src);

      // 1. Panel tab by vivExtData.panelId — most precise, avoids picking
      //    wrong tab when multiple tabs share the same origin (e.g. google.com)
      const byPanel =
        uuid &&
        tabs.find((t) => {
          try {
            return (
              JSON.parse(t.vivExtData || "{}").panelId === uuid && !t.discarded
            );
          } catch (_) {
            return false;
          }
        });
      // 2. Exact URL, not yet discarded
      const byUrl = tabs.find((t) => t.url === src && !t.discarded);
      // 3. Origin prefix, not yet discarded
      const byOrigin =
        origin && tabs.find((t) => t.url?.startsWith(origin) && !t.discarded);

      const tab = byPanel || byUrl || byOrigin || null;

      if (!tab) {
        L.warn("discard:tabNotFound", src.slice(0, 80));
        return;
      }
      if (tab.discarded) return;

      chrome.tabs.discard(tab.id, () => {
        if (chrome.runtime.lastError)
          L.error("discard:FAILED", tab.id, chrome.runtime.lastError.message);
      });
    });
  }

  // ── Hibernate scheduling ──────────────────────────────────────────────────────
  function tryHibernate(uuid) {
    if (hibernateEnabled.get(uuid) === false) return;

    const panel = findLivePanelByUUID(uuid);
    if (!panel) return;

    const wv = getWebview(panel);
    if (!wv) {
      L.warn("hibernate:noWebview", uuid.slice(-8));
      return;
    }

    checkMedia(panel, (playing) => {
      if (playing || isPanelVisible(panel)) return;

      const src = getBestSrc(wv, uuid);
      if (!src) {
        L.warn("hibernate:noSrc", uuid.slice(-8));
        return;
      }

      stopMediaPoll(uuid);
      discardTab(src, uuid);
    });
  }

  function scheduleHibernation(uuid) {
    if (hibernateEnabled.get(uuid) === false || hibernateTimers.has(uuid))
      return;
    hibernateTimers.set(
      uuid,
      setTimeout(() => {
        hibernateTimers.delete(uuid);
        tryHibernate(uuid);
      }, HIBERNATE_DELAY_MS),
    );
  }

  function cancelHibernation(uuid) {
    if (!hibernateTimers.has(uuid)) return;
    clearTimeout(hibernateTimers.get(uuid));
    hibernateTimers.delete(uuid);
  }

  // ── Media poll ────────────────────────────────────────────────────────────────
  function startMediaPoll(panel, uuid) {
    if (mediaPolls.has(uuid)) return;
    mediaPolls.set(
      uuid,
      setInterval(() => {
        const live = findLivePanelByUUID(uuid);
        if (!live || isPanelVisible(live)) {
          stopMediaPoll(uuid);
          return;
        }
        checkMedia(live, (playing) => {
          isPlayingMedia.set(uuid, playing);
          if (playing) {
            cancelHibernation(uuid);
            stopMediaPoll(uuid);
          }
        });
      }, MEDIA_POLL_INTERVAL_MS),
    );
  }

  function stopMediaPoll(uuid) {
    if (!mediaPolls.has(uuid)) return;
    clearInterval(mediaPolls.get(uuid));
    mediaPolls.delete(uuid);
  }

  // ── URL tracking ──────────────────────────────────────────────────────────────
  function onURL(panel, url) {
    if (!url || url === "about:blank") return;
    const wv = getWebview(panel);
    if (wv) wv.__lastSrc = url;

    const uuid = resolveUUIDByURL(url);
    if (uuid) {
      panel.__hibUUID = uuid;
      const idx = getLivePanels().indexOf(panel);
      if (idx >= 0) indexToUUID.set(idx, uuid);
      uuidSrcMap.set(uuid, url);
    }

    withState(panel, (u) => {
      if (isPanelVisible(panel)) {
        addToggleToHeader(panel);
      } else if (hibernateEnabled.get(u) !== false) {
        scheduleHibernation(u);
        startMediaPoll(panel, u);
      }
    });
  }

  // ── Panel observation ─────────────────────────────────────────────────────────
  function onVisibilityChange(panel) {
    const uuid = getUUID(panel);

    if (isPanelVisible(panel)) {
      if (uuid) {
        cancelHibernation(uuid);
        stopMediaPoll(uuid);
      }
      if (!panel.querySelector(".mod-auto-hibernate-toggle")) {
        if (uuid && storageLoaded.has(uuid)) addToggleToHeader(panel);
        else withState(panel, () => addToggleToHeader(panel));
      }
    } else {
      if (!uuid) return;
      checkMedia(panel, (playing) => {
        isPlayingMedia.set(uuid, playing);
        if (!playing) {
          scheduleHibernation(uuid);
          startMediaPoll(panel, uuid);
        }
      });
    }
  }

  function attachWebviewListeners(panel, wv) {
    wv.addEventListener("audio-state-changed", ({ audible }) => {
      const uuid = getUUID(panel);
      if (!uuid) return;
      isPlayingMedia.set(uuid, !!audible);
      if (audible) {
        cancelHibernation(uuid);
        stopMediaPoll(uuid);
      } else if (!isPanelVisible(panel)) {
        scheduleHibernation(uuid);
        startMediaPoll(panel, uuid);
      }
    });

    wv.addEventListener("loadstart", ({ url = "" }) => onURL(panel, url));
    wv.addEventListener("loadstop", () => {
      try {
        const live = typeof wv.getURL === "function" ? wv.getURL() : "";
        if (live && live !== "about:blank") onURL(panel, live);
      } catch (_) {}
    });

    new MutationObserver(() => {
      const src = wv.getAttribute("src") || "";
      if (src) onURL(panel, src);
    }).observe(wv, { attributes: true, attributeFilter: ["src"] });

    const src = wv.getAttribute("src") || "";
    if (src) onURL(panel, src);
  }

  function observePanel(panel) {
    if (!isLivePanel(panel) || panel.__hibObserved) return;
    panel.__hibObserved = true;

    const wv = getWebview(panel);
    if (wv) attachWebviewListeners(panel, wv);

    new MutationObserver(() => onVisibilityChange(panel)).observe(panel, {
      attributes: true,
      attributeFilter: ["class"],
    });

    if (isPanelVisible(panel)) withState(panel, () => addToggleToHeader(panel));
  }

  // ── Global reconciliation ─────────────────────────────────────────────────────
  function reconcile() {
    getLivePanels().forEach((panel, idx) => {
      if (!panel.__hibUUID && indexToUUID.has(idx))
        panel.__hibUUID = indexToUUID.get(idx);
      if (!panel.__hibObserved) observePanel(panel);

      if (
        isPanelVisible(panel) &&
        !panel.querySelector(".mod-auto-hibernate-toggle")
      ) {
        const uuid = getUUID(panel);
        if (uuid && storageLoaded.has(uuid)) addToggleToHeader(panel);
        else if (uuid) withState(panel, () => addToggleToHeader(panel));
      }
    });
  }

  function watchGlobal() {
    new MutationObserver(reconcile).observe(document.body, {
      childList: true,
      subtree: true,
    });
  }

  // ── Bootstrap ─────────────────────────────────────────────────────────────────
  function init() {
    if (_initialized) return true;
    if (!getLivePanels().length) return false;
    _initialized = true;
    reconcile();
    watchGlobal();
    return true;
  }

  const boot = new MutationObserver((_, obs) => {
    if (init()) obs.disconnect();
  });
  boot.observe(document.body, { childList: true, subtree: true });
})();
