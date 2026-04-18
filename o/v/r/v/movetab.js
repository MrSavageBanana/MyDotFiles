// vivaldi-multi-tab-move.js
// Fixes Vivaldi's broken multi-tab move behavior:
// When multiple tabs are highlighted and you trigger move-up or move-down,
// Vivaldi only moves the active tab. This mod moves the entire selection.
//
// Strategy: instead of moving all N selected tabs (causing cascading index
// shifts), we move the single "obstacle" tab on the other side of the group.
// One chrome.tabs.move call, no drift, selection is preserved.
//
// Pattern credit: selection detection and multi-tab querying taken from
// vivTreeTabs (tree.js) — specifically the highlighted-tab query in the
// Ctrl+Shift+H / Ctrl+Shift+L shortcut handler.

(function vivMultiTabMove() {
  "use strict";

  // ── Set these to match YOUR Vivaldi keyboard shortcut strings exactly ─────
  const MOVE_UP_SHORTCUT = "Ctrl+Shift+K"; // ← replace with your shortcut
  const MOVE_DOWN_SHORTCUT = "Ctrl+Shift+J"; // ← replace with your shortcut
  // ─────────────────────────────────────────────────────────────────────────

  // ── In-flight lock ────────────────────────────────────────────────────────
  // Prevents a second keypress from firing a move before the first
  // chrome.tabs.move + Vivaldi's internal reorder have fully settled.
  let moving = false;
  const MOVE_COOLDOWN_MS = 150; // tweak down if it feels sluggish, up if still sticky

  function moveSelectedTabs(direction) {
    if (moving) return; // drop the keypress — previous move hasn't settled yet
    moving = true;

    chrome.tabs.query({ currentWindow: true }, (allTabs) => {
      const sorted = [...allTabs].sort((a, b) => a.index - b.index);
      const selected = sorted.filter((t) => t.highlighted);

      if (selected.length === 0) {
        moving = false;
        return;
      }

      const selectedIds = new Set(selected.map((t) => t.id));
      let obstacle = null;

      if (direction === "up") {
        const firstPos = sorted.findIndex((t) => t.id === selected[0].id);
        if (firstPos === 0) {
          moving = false;
          return;
        }

        const candidate = sorted[firstPos - 1];
        if (selectedIds.has(candidate.id)) {
          moving = false;
          return;
        }

        obstacle = {
          tab: candidate,
          targetIndex: selected[selected.length - 1].index,
        };
      } else {
        const lastPos = sorted.findIndex(
          (t) => t.id === selected[selected.length - 1].id,
        );
        if (lastPos === sorted.length - 1) {
          moving = false;
          return;
        }

        const candidate = sorted[lastPos + 1];
        if (selectedIds.has(candidate.id)) {
          moving = false;
          return;
        }

        obstacle = { tab: candidate, targetIndex: selected[0].index };
      }

      chrome.tabs.move(obstacle.tab.id, { index: obstacle.targetIndex }, () => {
        // Hold the lock until Vivaldi has finished reordering internally.
        // Without this delay the next keypress queries before indices settle
        // and sees the same pre-move state, causing the phantom repeat move.
        setTimeout(() => {
          moving = false;
        }, MOVE_COOLDOWN_MS);
      });
    });
  }

  vivaldi.tabsPrivate.onKeyboardShortcut.addListener(
    (windowId, combination) => {
      if (windowId !== vivaldiWindowId) return;

      if (combination === MOVE_UP_SHORTCUT) {
        moveSelectedTabs("up");
      } else if (combination === MOVE_DOWN_SHORTCUT) {
        moveSelectedTabs("down");
      }
    },
  );
})();
