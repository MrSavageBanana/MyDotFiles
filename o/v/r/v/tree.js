// created with Claude. Account: Milobowler

(function vivTreeTabs() {
  'use strict';

  const STORAGE_KEY = 'vivTreeTabs_v1';

  const parentOf   = new Map(); // childId → parentId
  const childrenOf = new Map(); // parentId → [childId, ...]
  const urlOf      = new Map(); // tabId → url

  // ── Tree helpers ──────────────────────────────────────────────────────────

  function link(parentId, childId) {
    parentOf.set(childId, parentId);
    if (!childrenOf.has(parentId)) childrenOf.set(parentId, []);
    const arr = childrenOf.get(parentId);
    if (!arr.includes(childId)) arr.push(childId);
  }

  function unlink(tabId) {
    const pid  = parentOf.get(tabId);
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
      parentOf.delete(first);
      if (pid !== undefined) link(pid, first);
      for (const sib of rest) { parentOf.delete(sib); link(first, sib); }
    }
  }

  function getDepth(tabId, seen = new Set()) {
    if (seen.has(tabId) || seen.size > 20) return 0;
    seen.add(tabId);
    const pid = parentOf.get(tabId);
    return pid === undefined ? 0 : 1 + getDepth(pid, seen);
  }

  // ── Persistence ───────────────────────────────────────────────────────────

  function saveTree() {
    try {
      chrome.tabs.query({ currentWindow: true }, tabs => {
        const sorted = [...tabs].sort((a, b) => a.index - b.index);
        const posOf  = new Map(sorted.map((t, i) => [t.id, i]));

        const entries = sorted.map(t => ({
          url:       urlOf.get(t.id) || t.url || '',
          parentPos: parentOf.has(t.id)
                       ? (posOf.get(parentOf.get(t.id)) ?? null)
                       : null,
        }));

        localStorage.setItem(STORAGE_KEY, JSON.stringify(entries));
      });
    } catch (_) {}
  }

  function loadTree(tabs) {
    try {
      const raw = JSON.parse(localStorage.getItem(STORAGE_KEY) || 'null');
      if (!raw || !raw.length) return;

      const sorted = [...tabs].sort((a, b) => a.index - b.index);

      const urlToIds = new Map();
      for (const t of sorted) {
        const url = t.url || '';
        if (!urlToIds.has(url)) urlToIds.set(url, []);
        urlToIds.get(url).push(t.id);
      }

      const urlMatchCount = new Map();
      const posToTabId    = [];

      for (let i = 0; i < raw.length; i++) {
        const url  = raw[i].url || '';
        const ids  = urlToIds.get(url) || [];
        const used = urlMatchCount.get(url) || 0;
        posToTabId[i] = ids[used];
        if (ids[used] !== undefined) urlMatchCount.set(url, used + 1);
      }

      for (let i = 0; i < raw.length; i++) {
        const { parentPos } = raw[i];
        if (parentPos === null || parentPos === undefined) continue;
        const childId  = posToTabId[i];
        const parentId = posToTabId[parentPos];
        if (childId !== undefined && parentId !== undefined && childId !== parentId) {
          link(parentId, childId);
        }
      }
    } catch (_) {}
  }

  // ── Subtree placement ─────────────────────────────────────────────────────

  function getDescendants(tabId) {
    const result = new Set();
    const queue  = [...(childrenOf.get(tabId) || [])];
    while (queue.length) {
      const id = queue.shift();
      if (result.has(id)) continue;
      result.add(id);
      (childrenOf.get(id) || []).forEach(k => queue.push(k));
    }
    return result;
  }

  function placeAtEndOfSubtree(childId, parentId) {
    chrome.tabs.query({ currentWindow: true }, tabs => {
      const sorted      = [...tabs].sort((a, b) => a.index - b.index);
      const descendants = getDescendants(parentId);
      descendants.delete(childId);
      descendants.add(parentId);

      const parentPos = sorted.findIndex(t => t.id === parentId);
      if (parentPos === -1) return;

      let lastPos = parentPos;
      for (let i = parentPos + 1; i < sorted.length; i++) {
        if (descendants.has(sorted[i].id)) {
          lastPos = i;
        } else {
          break;
        }
      }

      const targetIndex = sorted[lastPos].index + 1;
      const childNow    = sorted.find(t => t.id === childId)?.index;
      if (childNow !== undefined && childNow !== targetIndex) {
        chrome.tabs.move(childId, { index: targetIndex });
      }
    });
  }

  // ── DOM stamping ──────────────────────────────────────────────────────────

  function stampTab(tabId) {
    const wrapper = document.getElementById(`tab-${tabId}`);
    if (!wrapper) return;
    const pos = wrapper.parentElement;
    if (!pos) return;

    const pid    = parentOf.get(tabId);
    const depth  = getDepth(tabId);
    const sibs   = pid !== undefined ? (childrenOf.get(pid) || []) : [];
    const isLast = !sibs.length || sibs[sibs.length - 1] === tabId;

    pos.style.setProperty('--tab-depth', depth);
    pos.setAttribute('data-depth', depth);
    pos.setAttribute('data-has-children', (childrenOf.get(tabId) || []).length > 0);

    if (pid !== undefined) {
      pos.setAttribute('data-parent-id', pid);
      pos.setAttribute('data-last-child', isLast);
    } else {
      pos.removeAttribute('data-parent-id');
      pos.removeAttribute('data-last-child');
    }
  }

  let stampTimer = null;
  function stampAll() {
    clearTimeout(stampTimer);
    stampTimer = setTimeout(() => {
      chrome.tabs.query({ currentWindow: true }, tabs => {
        tabs.forEach(t => stampTab(t.id));
        saveTree();
      });
    }, 80);
  }

  // ── Keyboard shortcut: Ctrl+Alt+T → new child of current tab ─────────────

  document.addEventListener('keydown', e => {
    if (e.ctrlKey && e.altKey && e.key === 't') {
      e.preventDefault();
      chrome.tabs.query({ active: true, currentWindow: true }, ([active]) => {
        if (!active) return;
        chrome.tabs.create({ openerTabId: active.id, active: true }, newTab => {
          link(active.id, newTab.id);
          placeAtEndOfSubtree(newTab.id, active.id);
          setTimeout(stampAll, 150);
        });
      });
    }
  }, true);

  // ── Tab events ────────────────────────────────────────────────────────────

  chrome.tabs.onCreated.addListener(tab => {
    urlOf.set(tab.id, tab.url || tab.pendingUrl || '');
    if (tab.openerTabId !== undefined) {
      link(tab.openerTabId, tab.id);
      placeAtEndOfSubtree(tab.id, tab.openerTabId);
    }
    setTimeout(stampAll, 120);
  });

  chrome.tabs.onUpdated.addListener((tabId, changeInfo) => {
    if (changeInfo.url !== undefined) {
      urlOf.set(tabId, changeInfo.url);
      stampAll();
    }
  });

  chrome.tabs.onRemoved.addListener(tabId => {
    unlink(tabId);
    urlOf.delete(tabId);
    stampAll();
  });

  chrome.tabs.onMoved.addListener(stampAll);

  // ── MutationObserver ──────────────────────────────────────────────────────
  //
  // Watches both childList (new tabs) and attribute changes on class.
  // When Vivaldi hibernates a tab it adds "isdiscarded" to the inner .tab
  // element — we catch that class mutation, walk up to find the tab-wrapper
  // id, and re-stamp immediately so indentation is never lost.

  function observe() {
    const root = document.querySelector('#tabs-container') ||
                 document.querySelector('.tab-strip') || document.body;

    new MutationObserver(mutations => {
      for (const mutation of mutations) {
        if (mutation.type !== 'attributes') continue;

        // Only care about class changes that add isdiscarded
        const el = mutation.target;
        if (!el.classList.contains('isdiscarded')) continue;

        // Walk up to find the tab-wrapper (id="tab-{n}")
        const wrapper = el.closest('[id^="tab-"]');
        if (!wrapper) continue;

        const tabId = parseInt(wrapper.id.slice(4), 10);
        if (!isNaN(tabId)) stampTab(tabId);
      }

      stampAll(); // debounced full pass for any other structural changes
    }).observe(root, {
      childList:      true,
      subtree:        true,
      attributes:     true,
      attributeFilter: ['class'],  // only class changes, keeps overhead low
    });
  }

  // ── Init ──────────────────────────────────────────────────────────────────

  function init() {
    chrome.tabs.query({ currentWindow: true }, tabs => {
      for (const t of tabs) urlOf.set(t.id, t.url || '');
      loadTree(tabs);
      for (const t of tabs)
        if (t.openerTabId !== undefined && !parentOf.has(t.id))
          link(t.openerTabId, t.id);
      stampAll();
    });
    observe();
  }

  function boot() {
    if (typeof chrome !== 'undefined' && chrome.tabs?.query) init();
    else setTimeout(boot, 200);
  }

  boot();
})();
