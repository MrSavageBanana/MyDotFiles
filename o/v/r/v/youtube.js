// ============================================================
// youtube.js — YouTube Homepage Blocker for Vivaldi
// ============================================================
// Created by Claude Nasr. Title: YouTube homepage blocker for Vivaldi custom.js
(function () {
    'use strict';

    const LOG = s => console.log('[YT Blocker]', s);

    function pageScript() {
        if (window.__ytBlockerActive) return;
        window.__ytBlockerActive = true;
        console.log('[YT Blocker] Active');

        function isHome() {
            return (location.pathname === '/' || location.pathname === '')
                && !location.search.includes('search_query=');
        }

        function nuke() {
            if (!isHome()) return false;

            var el = document.querySelector('ytd-browse[page-subtype="home"] #contents');
            if (el) {
                el.remove();
                console.log('[YT Blocker] Removed homepage #contents');
                return true;
            }

            var grids = document.querySelectorAll('ytd-rich-grid-renderer');
            if (grids.length) {
                grids.forEach(function(g) { g.remove(); });
                console.log('[YT Blocker] Removed ytd-rich-grid-renderer(s)');
                return true;
            }

            return false;
        }

        // Debounce helper — prevents the observer from firing nuke() 
        // hundreds of times per second on busy DOM mutations
        var debounceTimer = null;
        function debouncedNuke(delay) {
            clearTimeout(debounceTimer);
            debounceTimer = setTimeout(nuke, delay || 150);
        }

        // Initial pass
        setTimeout(nuke, 200);
        setTimeout(nuke, 1500);

        // SPA navigation watcher — only fires on actual URL change
        var lastUrl = location.href;
        new MutationObserver(function() {
            if (location.href !== lastUrl) {
                lastUrl = location.href;
                console.log('[YT Blocker] URL changed to ' + location.href);
                debouncedNuke(600);
            }
        }).observe(document.documentElement, { childList: true, subtree: true });

        // Content watcher — debounced so it doesn't thrash on every DOM change
        // Only active on the homepage
        new MutationObserver(function() {
            if (isHome()) debouncedNuke(150);
        }).observe(document.documentElement, { childList: true, subtree: true });
    }

    function injectIntoTab(tabId) {
        if (chrome.scripting?.executeScript) {
            chrome.scripting.executeScript({
                target: { tabId: tabId, allFrames: false },
                world: 'MAIN',
                func: pageScript
            }).then(() => {
                LOG('Injected into tab ' + tabId);
            }).catch(e => {
                LOG('Injection failed for tab ' + tabId + ': ' + e);
            });
        } else {
            LOG('chrome.scripting.executeScript not available');
        }
    }

    function isYouTubeUrl(url) {
        return url && url.includes('youtube.com');
    }

    function attachListeners() {
        LOG('Attaching listeners');

        if (chrome.tabs?.onUpdated) {
            chrome.tabs.onUpdated.addListener((tabId, changeInfo, tab) => {
                if (changeInfo.status === 'complete' && isYouTubeUrl(tab.url)) {
                    injectIntoTab(tabId);
                }
                if (changeInfo.url && isYouTubeUrl(changeInfo.url)) {
                    setTimeout(() => injectIntoTab(tabId), 700);
                }
            });
            LOG('Listening via chrome.tabs.onUpdated');
        }

        if (chrome.webNavigation?.onHistoryStateUpdated) {
            chrome.webNavigation.onHistoryStateUpdated.addListener(details => {
                if (details.frameId === 0 && isYouTubeUrl(details.url)) {
                    setTimeout(() => injectIntoTab(details.tabId), 700);
                }
            });
            LOG('Listening via chrome.webNavigation.onHistoryStateUpdated');
        }
    }

    let attempts = 0;
    function waitForApis() {
        if (chrome?.tabs?.onUpdated) {
            LOG('APIs ready after ' + attempts + ' attempt(s)');
            attachListeners();
        } else if (attempts++ < 40) {
            setTimeout(waitForApis, 250);
        } else {
            LOG('Gave up waiting for chrome.tabs API');
        }
    }

    waitForApis();
})();
