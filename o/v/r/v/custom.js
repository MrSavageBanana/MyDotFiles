// created with Claude. Account: Milobowler
// ─────────────────────────────────────────────────────────────────
//  Vivaldi Mod: Auto-hide tab bar when only one tab is open
//
//  Behaviour:
//   - 1 tab visible  → tab bar hides automatically
//   - 2+ tabs visible → tab bar shows automatically
//   - User manually toggles via KB shortcut → mod "pauses"
//   - Mod resumes on: tab open/close, tab switch, workspace switch
//
//  DOM structure (confirmed via diagnostic):
//   .inner > .tabbar-wrapper > .left.narrow > .left > .resize > .tab-strip
//
//  IMPORTANT: We use CSS (width:0 + overflow:hidden) to hide the tab
//  bar rather than removing it from the DOM. This way Vivaldi's own
//  KB shortcut can still manipulate .tabbar-wrapper freely without
//  hitting a "node is not a child" error.
//
//  Pause detection: we watch .inner for Vivaldi adding/removing
//  .tabbar-wrapper (which is what the KB shortcut does). If that
//  happens and we didn't cause it, we pause.
// ─────────────────────────────────────────────────────────────────

(function () {
  'use strict';

  let paused         = false;
  let scriptChanging = false;

  // ── Inject a <style> block we control ─────────────────────────
  const style = document.createElement('style');
  document.head.appendChild(style);

  function hideTabBar () {
    style.textContent = `
      .tabbar-wrapper {
        width: 0 !important;
        min-width: 0 !important;
        overflow: hidden !important;
        pointer-events: none !important;
      }
    `;
  }

  function showTabBar () {
    style.textContent = '';
  }

  // ── DOM helpers ────────────────────────────────────────────────
  function getInner () {
    return document.querySelector('.inner');
  }

  function isWrapperInDOM () {
    return !!document.querySelector('.tabbar-wrapper');
  }

  function tabCount () {
    const wrapper = document.querySelector('.tabbar-wrapper');
    if (!wrapper) return 0;
    return wrapper.querySelectorAll('.tab-wrapper').length;
  }

  function getActiveTabId () {
    return document.querySelector('.tab-wrapper.active')?.dataset?.id ?? null;
  }

  // ── Core: decide and apply ─────────────────────────────────────
  function applyVisibility () {
    if (paused) return;
    if (tabCount() <= 1) {
      hideTabBar();
    } else {
      showTabBar();
    }
  }

  function resume () {
    paused = false;
    applyVisibility();
  }

  // ── Observer: anchored to .inner ──────────────────────────────
  let mainObserver;

  function startObserver () {
    const inner = getInner();
    if (!inner) return;

    mainObserver?.disconnect();

    let prevCount       = tabCount();
    let prevActiveId    = getActiveTabId();
    let prevWrapperInDOM = isWrapperInDOM();

    mainObserver = new MutationObserver(() => {
      const nowWrapperInDOM = isWrapperInDOM();

      // ── Detect user KB toggle ──────────────────────────────
      // Vivaldi added or removed .tabbar-wrapper from the DOM
      if (nowWrapperInDOM !== prevWrapperInDOM) {
        prevWrapperInDOM = nowWrapperInDOM;

        if (!scriptChanging) {
          // User toggled — pause the mod and clear our CSS
          paused = true;
          showTabBar(); // remove our hiding so Vivaldi's state is clean
          return;
        }
      }

      // ── Detect tab state changes → resume mod ─────────────
      const nowCount    = tabCount();
      const nowActiveId = getActiveTabId();

      const stateChanged = (nowCount !== prevCount) ||
                           (nowActiveId !== prevActiveId);

      if (stateChanged) {
        prevCount    = nowCount;
        prevActiveId = nowActiveId;
        resume();
      }
    });

    mainObserver.observe(inner, {
      childList:       true,
      subtree:         true,
      attributes:      true,
      attributeFilter: ['class'],
    });
  }

  // ── Init ───────────────────────────────────────────────────────
  function init () {
    if (!getInner()) {
      setTimeout(init, 500);
      return;
    }
    applyVisibility();
    startObserver();
  }

  if (document.readyState === 'complete') {
    setTimeout(init, 1200);
  } else {
    window.addEventListener('load', () => setTimeout(init, 1200));
  }

})();
