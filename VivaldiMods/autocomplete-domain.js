(function () {
  "use strict";

  const STORAGE_KEY = "acdf_frecency";
  const DECAY = 0.9995; // per-hour decay factor

  // --- Storage ---

  async function load() {
    return new Promise((resolve) => {
      chrome.storage.local.get(STORAGE_KEY, (r) =>
        resolve(r[STORAGE_KEY] || {}),
      );
    });
  }

  async function save(data) {
    return new Promise((resolve) => {
      chrome.storage.local.set({ [STORAGE_KEY]: data }, resolve);
    });
  }

  // --- Frecency ---

  function score(visits) {
    const now = Date.now();
    return visits.reduce((acc, ts) => {
      const hoursAgo = (now - ts) / 3600000;
      return acc + Math.pow(DECAY, hoursAgo);
    }, 0);
  }

  async function record(url) {
    const data = await load();
    if (!data[url]) data[url] = [];
    data[url].push(Date.now());
    // Keep max 500 visits per URL to avoid bloat
    if (data[url].length > 500) data[url] = data[url].slice(-500);
    await save(data);
    console.log("[acdf] recorded", url);
  }

  async function bestMatch(typed) {
    const data = await load();
    const lower = typed.toLowerCase();
    let best = null;
    let bestScore = -1;

    for (const [url, visits] of Object.entries(data)) {
      const hostname = url.toLowerCase().split("/")[0];
      // Must match from the start of the hostname only
      if (!hostname.startsWith(lower)) continue;

      const s = score(visits);
      if (s > bestScore) {
        bestScore = s;
        best = url;
      }
    }

    return best;
  }
  // --- Helpers ---

  function looksLikeUrl(str) {
    return (
      /^[a-zA-Z0-9]/.test(str) &&
      !str.includes(" ") &&
      (str.includes(".") || str.includes("://") || str.includes("localhost"))
    );
  }

  function normalize(url) {
    try {
      const withProto = url.includes("://") ? url : "https://" + url;
      const parsed = new URL(withProto);
      // Strip trailing slash only if no path
      const path = parsed.pathname === "/" ? "" : parsed.pathname;
      return parsed.hostname + path + (parsed.search || "");
    } catch {
      return url;
    }
  }

  function getFiber(el, name) {
    const key = Object.keys(el).find((k) => k.startsWith("__reactFiber"));
    let f = el[key];
    while (f) {
      if (f.type?.name === name) return f;
      f = f.return;
    }
    return null;
  }

  // --- Main ---

  function init() {
    const input = document.querySelector("#urlFieldInput");
    if (!input) {
      setTimeout(init, 200);
      return;
    }

    input.addEventListener(
      "keydown",
      async (e) => {
        if (e.key !== "Enter" || e.altKey || e.ctrlKey || e.metaKey) return;

        const lt = getFiber(input, "LT");
        if (!lt) return;
        const props = lt.memoizedProps;
        const typed = props.typedUrl || "";
        if (!typed || typed.includes(" ")) return;

        const vivaldiBest = props.autocompleteData?.[0]?.destinationUrl || "";

        // Record whatever Vivaldi is about to navigate to, if it looks like a URL
        if (vivaldiBest && looksLikeUrl(vivaldiBest)) {
          record(normalize(vivaldiBest));
        }

        // Check our frecency data for a better match
        const ourBest = await bestMatch(typed);
        if (!ourBest) return;

        const vivaldiBestNorm = normalize(vivaldiBest);

        // Only override if our match is different from what Vivaldi picked
        if (ourBest === vivaldiBestNorm) return;

        e.preventDefault();
        e.stopImmediatePropagation();

        const nt = getFiber(input, "NT");
        const onValueChange = nt?.memoizedProps?.onValueChange;
        if (onValueChange) {
          const withProto = ourBest.includes("://")
            ? ourBest
            : "https://" + ourBest;
          console.log(
            "[acdf] frecency override:",
            vivaldiBest,
            "->",
            withProto,
          );
          onValueChange(withProto, true);
        }
      },
      true,
    );

    console.log("[acdf] frecency engine active");
  }

  // Expose for debugging
  window.acdf = {
    dump: async () => {
      const data = await load();
      const scored = Object.entries(data)
        .map(([url, visits]) => ({
          url,
          visits: visits.length,
          score: score(visits).toFixed(4),
        }))
        .sort((a, b) => b.score - a.score);
      console.table(scored);
      return scored;
    },
    clear: async () => {
      await save({});
      console.log("[acdf] cleared");
    },
    record: async (url) => {
      await record(normalize(url));
    },
    // Seed with array of [url, visitCount] pairs
    // e.g. acdf.seed([['github.com', 50], ['youtube.com', 100]])
    seed: async (pairs) => {
      const data = await load();
      const now = Date.now();
      for (const [url, count] of pairs) {
        const key = normalize(url);
        if (!data[key]) data[key] = [];
        for (let i = 0; i < count; i++) {
          data[key].push(now - Math.random() * 30 * 24 * 3600000);
        }
      }
      await save(data);
      console.log("[acdf] seeded", pairs.length, "URLs");
    },
  };

  init();
})();
