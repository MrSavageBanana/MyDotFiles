// created with Claude. Account: Milobowler

setTimeout(() => {
    const CONFIG = {
        wallpaperUrl: 'http://localhost:12345/wallpaper',
        pollInterval: 16
    };

    let hasInjectedStyle = false;

    function getStartPage() {
        return document.querySelector('.webpageview.active .internal-page');
    }

    function injectStyle(internalPage) {
        if (hasInjectedStyle) return;
        const style = document.createElement('style');
        style.id = 'wallpaper-override';
        style.textContent = `
            .startpage, .startpage body, #startpage {
                background-color: transparent !important;
            }
        `;
        internalPage.appendChild(style);

        // Set the wallpaper directly on the internal-page element
        internalPage.style.backgroundImage = `url("${CONFIG.wallpaperUrl}")`;
        internalPage.style.backgroundRepeat = 'no-repeat';
        internalPage.style.backgroundAttachment = 'scroll';
        hasInjectedStyle = true;
    }

    async function updateWallpaper() {
        const internalPage = getStartPage();

	console.log('[wallpaper] internal-page found:', !!internalPage, internalPage);  
        // Only run on the start page
        if (!internalPage) return;

        // Inject style once when start page is first found
        injectStyle(internalPage);

        try {
            const res = await fetch('http://localhost:12345/pos');
            if (!res.ok) throw new Error(`HTTP ${res.status}`);
            const { bgX, bgY, monW, monH } = await res.json();

            internalPage.style.backgroundSize     = `${monW}px ${monH}px`;
            internalPage.style.backgroundPosition = `-${Math.round(bgX)}px -${Math.round(bgY)}px`;
        } catch (e) {
            // Bridge not running — wallpaper still shows, just won't track position
        }
    }

    // Reset injection flag when tabs switch so we re-inject on new start pages
    chrome.tabs.onActivated.addListener(() => {
        hasInjectedStyle = false;
    });

    setInterval(updateWallpaper, CONFIG.pollInterval);

}, 3000);
