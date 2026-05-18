// created with Claude. Account: Milobowler

// Give Vivaldi 3 seconds to fully load its UI before we start measuring.
// The .active.webpageview element won't exist until the UI is ready.
setTimeout(() => {
    let lastLeft = -1;
    let lastTop  = -1;

    async function syncOffset() {
        // Find the active tab's content container inside Vivaldi's UI
        const webview = document.querySelector('.active.webpageview');
        if (!webview) return;

        const rect = webview.getBoundingClientRect();

        // Only POST when the offset actually changes — avoids a constant flood
        // of identical requests to the Python bridge.
        if (rect.left === lastLeft && rect.top === lastTop) return;
        lastLeft = rect.left;
        lastTop  = rect.top;

        try {
            // Send the panel/tab bar thickness to the Python hub
            await fetch('http://localhost:12345/offset', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ left: rect.left, top: rect.top })
            });
        } catch (e) {
            // Python bridge isn't running yet — silently ignore
        }
    }

    // Check offsets 10 times a second. The change-detection above means
    // we only send a request when the Vivaldi panel state actually changes.
    setInterval(syncOffset, 16);

}, 3000);
