// created with Claude. Account: Milobowler, and Nasr
// Indenting and Outdenting logic added
// Modified to remove Hibernation and session persistence since neither worked
// Now, the indenting and outdenting work. The shortcuts aren't that hard either. Same Vim shortcuts I love
// This now makes it so all tabs can be indented or outdented except the root can't be outdented since there is nowhere to go
// This now makes it so there isn't implicit parents when a parent dies This now makes it so there isn't implicit parents when a parent dies. ALl children stay at their level.

(function vivTreeTabs() {
  "use strict";

  // URL opened by Ctrl+T (new root tab).
  // Set to any string, or leave undefined for Vivaldi's default new tab page.
  const ROOT_TAB_URL = "vivaldi://startpage";

  const parentOf = new Map(); // childId → parentId
  const childrenOf = new Map(); // parentId → [childId, ...]
  const urlOf = new Map(); // tabId → url

  // ── Persistence ───────────────────────────────────────────────────────────

  const TREE_NS = "vivTree";
  let _skipPersist = false;

  function readVivExtData(tab) {
    try {
      const raw = tab.vivExtData;
      console.log(
        `[vivTree] readVivExtData: tab=${tab.id} type=${typeof raw} value=`,
        raw,
      );
      if (!raw) return {};
      if (typeof raw === "string") return JSON.parse(raw);
      if (typeof raw === "object") return raw;
    } catch (e) {
      console.warn(
        `[vivTree] readVivExtData: parse error for tab=${tab.id}`,
        e,
      );
    }
    return {};
  }

  function persistTab(tabId) {
    if (_skipPersist) return;
    chrome.tabs.get(tabId, (tab) => {
      if (chrome.runtime.lastError || !tab) return;
      const ext = readVivExtData(tab);
      const parentId = parentOf.get(tabId) ?? null;
      ext[TREE_NS] = { parentId };
      console.log(`[vivTree] persistTab: tab=${tabId} parentId=${parentId}`);
      chrome.tabs.update(tabId, { vivExtData: JSON.stringify(ext) }, () => {
        if (chrome.runtime.lastError) {
          console.warn(
            `[vivTree] persistTab: write failed for tab=${tabId}`,
            chrome.runtime.lastError.message,
          );
        }
      });
    });
  }

  function restoreFromVivExtData(tabs) {
    const tabIds = new Set(tabs.map((t) => t.id));
    console.log(
      `[vivTree] restoreFromVivExtData: checking ${tabs.length} tabs`,
    );
    _skipPersist = true;
    for (const tab of tabs) {
      if (parentOf.has(tab.id)) {
        console.log(
          `[vivTree] restore: tab=${tab.id} already linked, skipping`,
        );
        continue;
      }
      const record = readVivExtData(tab)[TREE_NS];
      if (
        !record ||
        record.parentId === null ||
        record.parentId === undefined
      ) {
        console.log(`[vivTree] restore: tab=${tab.id} has no vivTree record`);
        continue;
      }
      console.log(
        `[vivTree] restore: tab=${tab.id} stored parentId=${record.parentId}, parent exists=${tabIds.has(record.parentId)}`,
      );

      if (tabIds.has(record.parentId)) link(record.parentId, tab.id);
    }
    _skipPersist = false;
  }

  let lastActiveTabId = null;
  let nextTabIsRoot = false;

  // ── Tree helpers ──────────────────────────────────────────────────────────

  function link(parentId, childId) {
    parentOf.set(childId, parentId);
    if (!childrenOf.has(parentId)) childrenOf.set(parentId, []);
    const arr = childrenOf.get(parentId);
    if (!arr.includes(childId)) arr.push(childId);
    persistTab(childId);
  }

  function unlink(tabId) {
    const pid = parentOf.get(tabId);
    const kids = [...(childrenOf.get(tabId) || [])];
    childrenOf.delete(tabId);
    parentOf.delete(tabId);

    if (pid !== undefined) {
      const arr = childrenOf.get(pid);
      if (arr) {
        const i = arr.indexOf(tabId);
        if (i !== -1) arr.splice(i, 1);
        if (!arr.length) childrenOf.delete(pid);
      }
    }

    if (kids.length) {
      const [first, ...rest] = kids;
      const firstHasChildren = (childrenOf.get(first) || []).length > 0;

      if (firstHasChildren) {
        // First child already has its own subtree — let it absorb its siblings
        parentOf.delete(first);
        if (pid !== undefined) link(pid, first);
        else persistTab(first); // became root — link() not called
        for (const sib of rest) {
          parentOf.delete(sib);
          link(first, sib);
        }
      } else {
        // No implicit new parent — all children are promoted independently
        for (const kid of kids) {
          parentOf.delete(kid);
          if (pid !== undefined) link(pid, kid);
          else persistTab(kid); // became root — link() not called
        }
      }
    }
  }

  function getDepth(tabId, seen = new Set()) {
    if (seen.has(tabId) || seen.size > 20) return 0;
    seen.add(tabId);
    const pid = parentOf.get(tabId);
    return pid === undefined ? 0 : 1 + getDepth(pid, seen);
  }

  function getRoot(tabId) {
    let cur = tabId;
    const seen = new Set();
    while (parentOf.has(cur) && !seen.has(cur)) {
      seen.add(cur);
      cur = parentOf.get(cur);
    }
    return cur;
  }

  function getDescendants(tabId) {
    const result = new Set();
    const queue = [...(childrenOf.get(tabId) || [])];
    while (queue.length) {
      const id = queue.shift();
      if (result.has(id)) continue;
      result.add(id);
      (childrenOf.get(id) || []).forEach((k) => queue.push(k));
    }
    return result;
  }

  // ── Tab placement ─────────────────────────────────────────────────────────
  //
  // Places `tabId` immediately after the last member of `referenceId`'s
  // subtree. `tabId` is excluded from the query so the target index is
  // computed from a stable list — no left-shift correction needed, and
  // chrome.tabs.move is always called unconditionally.

  function moveAfterSubtree(tabId, referenceId) {
    chrome.tabs.query({ currentWindow: true }, (tabs) => {
      const others = [...tabs]
        .filter((t) => t.id !== tabId)
        .sort((a, b) => a.index - b.index);

      const group = getDescendants(referenceId);
      group.add(referenceId);

      const refPos = others.findIndex((t) => t.id === referenceId);
      if (refPos === -1) return;

      let lastPos = refPos;
      for (let i = refPos + 1; i < others.length; i++) {
        if (group.has(others[i].id)) lastPos = i;
        else break;
      }

      chrome.tabs.move(tabId, { index: others[lastPos].index + 1 });
    });
  }

  // ── Position enforcement ──────────────────────────────────────────────────
  //
  // Runs on every stampAll pass. Fixes one out-of-place child per call;
  // subsequent debounced passes clean up any remaining violations.

  function enforcePositions(tabs) {
    const sorted = [...tabs].sort((a, b) => a.index - b.index);

    for (let i = 0; i < sorted.length; i++) {
      const tabId = sorted[i].id;
      const parentId = parentOf.get(tabId);
      if (parentId === undefined) continue;

      const parentIdx = sorted.findIndex((t) => t.id === parentId);
      if (parentIdx === -1) continue;

      if (i <= parentIdx) {
        moveAfterSubtree(tabId, parentId);
        return;
      }

      const kin = getDescendants(parentId);
      kin.add(parentId);
      for (let j = parentIdx + 1; j < i; j++) {
        if (!kin.has(sorted[j].id)) {
          moveAfterSubtree(tabId, parentId);
          return;
        }
      }
    }
  }

  // ── DOM stamping ──────────────────────────────────────────────────────────

  function stampTab(tabId) {
    const wrapper = document.getElementById(`tab-${tabId}`);
    if (!wrapper) return;
    const pos = wrapper.parentElement;
    if (!pos) return;

    const pid = parentOf.get(tabId);
    const depth = getDepth(tabId);
    const sibs = pid !== undefined ? childrenOf.get(pid) || [] : [];
    const isLast = !sibs.length || sibs[sibs.length - 1] === tabId;

    pos.style.setProperty("--tab-depth", depth);
    pos.setAttribute("data-depth", depth);
    pos.setAttribute(
      "data-has-children",
      (childrenOf.get(tabId) || []).length > 0,
    );

    if (pid !== undefined) {
      pos.setAttribute("data-parent-id", pid);
      pos.setAttribute("data-last-child", isLast);
    } else {
      pos.removeAttribute("data-parent-id");
      pos.removeAttribute("data-last-child");
    }
  }

  let stampTimer = null;
  function stampAll() {
    clearTimeout(stampTimer);
    stampTimer = setTimeout(() => {
      chrome.tabs.query({ currentWindow: true }, (tabs) => {
        tabs.forEach((t) => stampTab(t.id));
        enforcePositions(tabs);
      });
    }, 80);
  }

  // ── Outdent (Ctrl+Shift+H) ───────────────────────────────────────────────
  //
  // Moves each selected tab one level up in the tree (makes it a sibling of
  // its current parent, placed right after that parent's subtree).
  //
  // Rules:
  //   - Root tabs are silently skipped.
  //   - Cascade: if tab T is being outdented and T has children not in the
  //     selection, those children are automatically added to the outdent set.
  //     This prevents a parent moving up while its children are left stranded.
  //   - Processing order: shallowest first, so parent relationships are
  //     updated before their children are processed.

  function doOutdent(tabIds) {
    const set = new Set(tabIds.filter((id) => parentOf.has(id))); // skip roots

    // Cascade: expand set to include all children of tabs being outdented
    let changed = true;
    while (changed) {
      changed = false;
      for (const id of [...set]) {
        for (const childId of childrenOf.get(id) || []) {
          if (!set.has(childId)) {
            set.add(childId);
            changed = true;
          }
        }
      }
    }

    // Sort shallowest first so each tab's new parent is already in its
    // correct place when we get to processing the tab's children.
    const ordered = [...set].sort((a, b) => getDepth(a) - getDepth(b));
    if (!ordered.length) return;

    // Capture the old parent before any tree modifications — we need it later
    // to compute the correct strip position for each outdented tab.
    const oldParents = new Map(ordered.map((id) => [id, parentOf.get(id)]));

    for (const tabId of ordered) {
      // Re-read current parent: an ancestor processed earlier in this loop
      // may have already re-parented this tab.
      const curParent = parentOf.get(tabId);
      if (curParent === undefined) continue; // already root after cascade

      const grandParent = parentOf.get(curParent); // undefined → tabId becomes root

      // Remove tabId from curParent's children
      const sibs = childrenOf.get(curParent);
      if (sibs) {
        const i = sibs.indexOf(tabId);
        if (i !== -1) sibs.splice(i, 1);
        if (!sibs.length) childrenOf.delete(curParent);
      }
      parentOf.delete(tabId);

      if (grandParent !== undefined) {
        // Insert into grandparent's children immediately after curParent
        if (!childrenOf.has(grandParent)) childrenOf.set(grandParent, []);
        const uncles = childrenOf.get(grandParent);
        // Remove from any existing position first
        const tIdx = uncles.indexOf(tabId);
        if (tIdx !== -1) uncles.splice(tIdx, 1);
        // Insert after curParent
        const pIdx = uncles.indexOf(curParent);
        uncles.splice(pIdx + 1, 0, tabId);
        parentOf.set(tabId, grandParent);
      }
      // else: tabId is now a root (no parentOf entry)
    }

    // Move each tab in the strip to just after its old parent's subtree.
    // Process shallowest first so earlier moves settle before later ones query.
    for (const tabId of ordered) {
      moveAfterSubtree(tabId, oldParents.get(tabId));
    }

    for (const tabId of ordered) persistTab(tabId);
    stampAll();
  }

  // ── Indent (Ctrl+Shift+L) ──────────────────────────────────────────────
  //
  // Moves each selected tab one level deeper by making it the last child of
  // the sibling immediately above it.
  //
  // Rules:
  //   - Root tabs are silently skipped.
  //   - A tab is skipped if it has no sibling above it (nothing to parent it).
  //   - Processing order: shallowest first to avoid sibling list corruption
  //     when multiple siblings in the same parent are selected.

  function doIndent(tabIds) {
    chrome.tabs.query({ currentWindow: true }, (allTabs) => {
      const strip = [...allTabs].sort((a, b) => a.index - b.index);

      const ordered = [...new Set(tabIds)]
        .filter((id) => {
          if (parentOf.has(id)) {
            // Non-root: must have a sibling above
            const sibs = childrenOf.get(parentOf.get(id)) || [];
            return sibs.indexOf(id) > 0; // must have a sibling above
          } else {
            // Root: must have any tab above it in the strip
            return strip.findIndex((t) => t.id === id) > 0;
          }
        })
        .sort((a, b) => getDepth(a) - getDepth(b));

      if (!ordered.length) return;

      for (const tabId of ordered) {
        if (parentOf.has(tabId)) {
          // Non-root: nest under the sibling above (existing logic)
          const curParent = parentOf.get(tabId);
          if (curParent === undefined) continue;

          const sibs = childrenOf.get(curParent) || [];
          const myIdx = sibs.indexOf(tabId);
          if (myIdx <= 0) continue; // no sibling above (may have shifted)

          const newParent = sibs[myIdx - 1];

          // Remove from current parent
          sibs.splice(myIdx, 1);
          if (!sibs.length) childrenOf.delete(curParent);
          parentOf.delete(tabId);

          // Append as last child of the sibling above
          link(newParent, tabId);

          // Move to end of new parent's subtree in the strip
          moveAfterSubtree(tabId, newParent);
        } else {
          // Root: nest under whatever tab is immediately above in the strip
          const idx = strip.findIndex((t) => t.id === tabId);
          if (idx <= 0) continue;

          const newParent = strip[idx - 1].id;
          link(newParent, tabId);
          moveAfterSubtree(tabId, newParent);
        }
      }

      stampAll();
    });
  }

  // ── Keyboard shortcuts ────────────────────────────────────────────────────
  //
  // Ctrl+T   → new root tab (placed after current root's subtree)
  // Ctrl+Shift+H  → outdent selected tab(s) one level
  // Ctrl+Shift+L→ indent selected tab(s) one level
  //
  // vivaldi.tabsPrivate.onKeyboardShortcut fires globally regardless of focus,
  // solving the renderer-process boundary that blocked document.addEventListener.

  vivaldi.tabsPrivate.onKeyboardShortcut.addListener(
    (windowId, combination) => {
      if (windowId !== vivaldiWindowId) return;

      if (combination === "Ctrl+T") {
        chrome.tabs.query({ active: true, currentWindow: true }, ([active]) => {
          if (!active) return;
          const rootId = getRoot(active.id);
          nextTabIsRoot = true;
          const opts = { active: true };
          if (ROOT_TAB_URL !== undefined) opts.url = ROOT_TAB_URL;
          chrome.tabs.create(opts, (newTab) => {
            moveAfterSubtree(newTab.id, rootId);
            setTimeout(stampAll, 150);
          });
        });
        return;
      }

      if (combination === "Ctrl+Shift+H" || combination === "Ctrl+Shift+L") {
        chrome.tabs.query(
          { highlighted: true, currentWindow: true },
          (tabs) => {
            const ids = tabs.map((t) => t.id);
            if (combination === "Ctrl+Shift+H") doOutdent(ids);
            else doIndent(ids);
          },
        );
      }
    },
  );

  // ── Tab events ────────────────────────────────────────────────────────────

  chrome.tabs.onActivated.addListener(({ tabId }) => {
    lastActiveTabId = tabId;
  });

  chrome.tabs.onCreated.addListener((tab) => {
    urlOf.set(tab.id, tab.url || tab.pendingUrl || "");

    if (nextTabIsRoot) {
      nextTabIsRoot = false;
      setTimeout(stampAll, 120);
      return;
    }

    const parentId =
      tab.openerTabId !== undefined ? tab.openerTabId : lastActiveTabId;

    if (parentId !== undefined && parentId !== null && parentId !== tab.id) {
      link(parentId, tab.id);
      moveAfterSubtree(tab.id, parentId);
    }

    setTimeout(stampAll, 120);
  });

  chrome.tabs.onUpdated.addListener((tabId, changeInfo, tab) => {
    if (changeInfo.url !== undefined) {
      urlOf.set(tabId, changeInfo.url);
      stampAll();
    }

    // Tab woke from hibernation — re-apply depth attributes.
    if (changeInfo.status === "loading") {
      console.log(
        `[vivTree] wakeup detected: tab=${tabId} inMemoryParent=${parentOf.get(tabId) ?? "none"}`,
      );
      if (parentOf.has(tabId)) {
        // In-memory state is intact; just re-stamp.
        console.log(
          `[vivTree] wakeup: in-memory parent intact, re-stamping tab=${tabId}`,
        );
        setTimeout(() => stampTab(tabId), 150);
        return;
      }
      // In-memory state was lost (e.g. after browser restart mid-session).
      // Try to restore parent from vivExtData.
      const record = readVivExtData(tab)[TREE_NS];
      console.log(
        `[vivTree] wakeup: vivExtData record for tab=${tabId}`,
        record ?? "none",
      );
      if (
        !record ||
        record.parentId === null ||
        record.parentId === undefined
      ) {
        console.log(
          `[vivTree] wakeup: no stored parent for tab=${tabId}, leaving as root`,
        );
        return;
      }
      return;
      chrome.tabs.get(record.parentId, (parentTab) => {
        if (!chrome.runtime.lastError && parentTab) {
          console.log(
            `[vivTree] wakeup: restoring tab=${tabId} under parentId=${record.parentId}`,
          );
          link(record.parentId, tabId);
        } else {
          console.warn(
            `[vivTree] wakeup: stored parentId=${record.parentId} not found for tab=${tabId}`,
          );
        }
        link(record.parentId, tabId);
        setTimeout(() => stampTab(tabId), 150);
      });
    }
  });

  chrome.tabs.onRemoved.addListener((tabId) => {
    unlink(tabId);
    urlOf.delete(tabId);
    if (lastActiveTabId === tabId) lastActiveTabId = null;
    stampAll();
  });

  chrome.tabs.onMoved.addListener(stampAll);

  // ── MutationObserver ──────────────────────────────────────────────────────

  function observe() {
    const root =
      document.querySelector("#tabs-container") ||
      document.querySelector(".tab-strip") ||
      document.body;

    new MutationObserver(() => stampAll()).observe(root, {
      childList: true,
      subtree: true,
    });
  }

  // ── Init ──────────────────────────────────────────────────────────────────

  function init() {
    chrome.tabs.query({ currentWindow: true }, (tabs) => {
      for (const t of tabs) urlOf.set(t.id, t.url || "");
      for (const t of tabs)
        if (t.openerTabId !== undefined && !parentOf.has(t.id))
          link(t.openerTabId, t.id);
      restoreFromVivExtData(tabs); // fill in anything not covered by openerTabId
      const active = tabs.find((t) => t.active);
      if (active) lastActiveTabId = active.id;
      stampAll();
    });
    observe();
  }

  function boot() {
    if (typeof chrome !== "undefined" && chrome.tabs?.query) init();
    else setTimeout(boot, 200);
  }

  boot();
})();
