// created with Claude. Account: Burhan Ra'if Kouri

/**
 * Todoist Quick-Add Dialog Mod for Vivaldi
 *
 * Opens a floating popup webview for Todoist Quick-Add via Ctrl+Shift+A.
 * Press Esc or Ctrl+Shift+A again to close.
 *
 * ─── VARIABLES ────────────────────────────────────────────────────────────────
 */
const TODOIST_URL =
  "https://app.todoist.com/add?content=&view_mode=window&wrapper=ChromeExtension&source=keyboard";

// Size of the Todoist quick-add card itself (px).
const CARD_WIDTH = 576;
const CARD_HEIGHT = 285;

// How many px to crop from each side of the dialog.
const CROP = 30;

// Extra webview viewport height (px) reserved below the card so Todoist's
// React portals (date picker, labels, priority…) have space to render into.
// The background will be transparent so this area is invisible until a popup
// actually appears.
const POPUP_EXTRA_HEIGHT = 350;

// Vertical offset from the top of the browser viewport (px).
const DIALOG_TOP_OFFSET = 80;

// Nudge left/right from center (positive = right, negative = left).
const DIALOG_HORIZONTAL_OFFSET = 0;

// Border-radius of the Todoist card (px).
const CARD_BORDER_RADIUS = 10;
// ──────────────────────────────────────────────────────────────────────────────

(() => {
  const DIALOG_WIDTH = CARD_WIDTH - CROP * 2;
  const DIALOG_HEIGHT = CARD_HEIGHT - CROP * 2;

  setTimeout(function waitReady() {
    if (!document.getElementById("browser")) {
      return setTimeout(waitReady, 300);
    }
    new TodoistDialogMod();
  }, 300);

  class TodoistDialogMod {
    #visible = false;
    #webview = null;
    #dialogBox = null;
    #overlay = null;
    #dialogContainer = null;
    #stopPointer = null;

    constructor() {
      this.#injectStyles();
      this.#buildPersistentDOM();
      this.#preload();
      vivaldi.tabsPrivate.onKeyboardShortcut.addListener(
        this.#onKeyCombo.bind(this),
      );
    }

    #injectStyles() {
      if (document.getElementById("todoist-dialog-style")) return;
      const style = document.createElement("style");
      style.id = "todoist-dialog-style";
      style.textContent = `
        @keyframes todoist-dialog-in {
          from { opacity: 0; transform: translateX(-50%) translateY(-10px) scale(0.97); }
          to   { opacity: 1; transform: translateX(-50%) translateY(0)     scale(1);    }
        }
        @keyframes todoist-dialog-out {
          from { opacity: 1; transform: translateX(-50%) translateY(0)     scale(1);    }
          to   { opacity: 0; transform: translateX(-50%) translateY(-10px) scale(0.97); }
        }
      `;
      document.head.appendChild(style);
    }

    #buildPersistentDOM() {
      this.#webview = document.createElement("webview");
      this.#webview.id = "todoist-persistent-webview";
      this.#webview.tab_id = "todoist-persistent-webviewtabId";
      this.#webview.style.cssText = `
        position: absolute;
        top:  -${CROP}px;
        left: -${CROP}px;
        width:  ${CARD_WIDTH}px;
        height: ${CARD_HEIGHT + POPUP_EXTRA_HEIGHT}px;
        border: none;
        display: block;
      `;

      // On each page load: strip the dark body background and wire up the
      // popup detector so we know exactly how far to expand the clip region.
      this.#webview.addEventListener("loadstop", () => {
        this.#injectTransparentBackground();
        this.#injectPopupDetector();
      });

      // React to portal open/close signals from the webview.
      this.#webview.addEventListener("consolemessage", (e) =>
        this.#onWebviewMessage(e.message),
      );

      this.#dialogBox = document.createElement("div");
      this.#dialogBox.className = "todoist-dialog-box";
      this.#dialogBox.style.cssText = `
        position: absolute;
        width:  ${DIALOG_WIDTH}px;
        height: ${DIALOG_HEIGHT}px;
        top:  ${DIALOG_TOP_OFFSET}px;
        left: calc(50% + ${DIALOG_HORIZONTAL_OFFSET}px);
        transform: translateX(-50%);
        z-index: 1;
        overflow: visible;
        clip-path: ${this.#clipCard()};
        border-radius: ${CARD_BORDER_RADIUS}px;
        box-shadow: 0 8px 32px rgba(0,0,0,0.45);
      `;
      this.#dialogBox.appendChild(this.#webview);

      // position: absolute — moves with the container
      this.#overlay = document.createElement("div");
      this.#overlay.style.cssText = `
        position: absolute;
        inset: 0;
        background: transparent;
      `;
      this.#overlay.addEventListener("click", () => this.#hideDialog());

      // The ONLY position:fixed element. Everything else is absolute inside it.
      // Off-screen by default — the webview loads and stays fully alive here.
      this.#dialogContainer = document.createElement("div");
      this.#dialogContainer.className = "todoist-dialog-root";
      this.#dialogContainer.style.cssText = `
        position: fixed;
        inset: 0;
        z-index: 2147483645;
        pointer-events: none;
        left: -99999px;
      `;
      this.#dialogContainer.appendChild(this.#overlay);
      this.#dialogContainer.appendChild(this.#dialogBox);

      document.getElementById("browser").appendChild(this.#dialogContainer);
    }

    // ── clip-path helpers ────────────────────────────────────────────────────

    // Normal state: crop all four edges exactly, round all corners.
    // The webview's -CROP offset already places its edges outside this box's
    // coordinate space, so inset(0) clips them without any explicit amount.
    #clipCard() {
      const r = `${CARD_BORDER_RADIUS}px`;
      return `inset(0 0 0 0 round ${r})`;
    }

    // Popup state: extend the clip region downward by exactly what the popup
    // needs plus a small breathing pad. Top corners stay rounded; bottom
    // corners are squared off since the popup panel lives below the card.
    #clipPopup(extraPx) {
      const r = `${CARD_BORDER_RADIUS}px`;
      return `inset(0 0 -${extraPx + 12}px 0 round ${r} ${r} 0 0)`;
    }

    // ── webview injections ───────────────────────────────────────────────────

    // Make the webview's page background transparent so the extra viewport
    // height below the card is invisible rather than showing Todoist's dark
    // background colour.
    #injectTransparentBackground() {
      this.#webview.insertCSS({
        code: `html, body { background: transparent !important; }`,
      });
    }

    // Inject a MutationObserver that watches document.body for React portal
    // elements (Todoist renders every popup — date, labels, priority — as a
    // direct child of body outside the app root). When portals appear it
    // reports their exact bottom edge in webview-viewport pixels; when they
    // disappear it signals close.
    #injectPopupDetector() {
      this.#webview.executeScript({
        code: `
          (function () {
            if (window.__tmd) return;
            window.__tmd = true;

            function appRoot() {
              return (
                document.getElementById('root') ||
                document.querySelector('[data-reactroot]') ||
                document.body.firstElementChild
              );
            }

            function report() {
              const root = appRoot();
              const portals = [...document.body.children].filter(
                (el) => el !== root && el.children.length > 0,
              );

              if (!portals.length) {
                console.log('TMD:close');
                return;
              }

              let maxBottom = 0;
              for (const p of portals) {
                const b = p.getBoundingClientRect().bottom;
                if (b > maxBottom) maxBottom = b;
              }
              console.log('TMD:open:' + Math.ceil(maxBottom));
            }

            new MutationObserver(report).observe(document.body, {
              childList: true,
            });
          })();
        `,
      });
    }

    // ── portal message handler ───────────────────────────────────────────────

    #onWebviewMessage(msg) {
      if (!msg.startsWith("TMD:")) return;

      if (msg === "TMD:close") {
        // Restore the normal card crop.
        this.#dialogBox.style.clipPath = this.#clipCard();
        return;
      }

      if (msg.startsWith("TMD:open:")) {
        // popupBottom is in webview-viewport px (origin = webview top-left).
        // The webview is offset -CROP inside the dialog box, so:
        //   dialog_y = webview_y - CROP
        // Extra pixels the popup needs below the dialog box's CSS bottom:
        //   extra = (webview_y - CROP) - DIALOG_HEIGHT
        const popupBottom = parseInt(msg.slice(9), 10);
        const extra = popupBottom - CROP - DIALOG_HEIGHT;

        if (extra > 0) {
          this.#dialogBox.style.clipPath = this.#clipPopup(extra);
        }
        // If extra <= 0 the popup fits within the normal crop — leave it alone.
      }
    }

    // ── preload ──────────────────────────────────────────────────────────────

    #preload() {
      this.#webview.setAttribute("src", TODOIST_URL);
    }

    // ── show / hide ──────────────────────────────────────────────────────────

    #showDialog() {
      chrome.windows.getLastFocused((win) => {
        if (
          win.id !== vivaldiWindowId ||
          win.state === chrome.windows.WindowState.MINIMIZED
        )
          return;

        this.#visible = true;

        this.#dialogContainer.style.left = "0";
        this.#dialogContainer.style.pointerEvents = "auto";

        this.#dialogBox.style.animation =
          "todoist-dialog-in 0.18s cubic-bezier(0.2, 0.8, 0.2, 1) forwards";

        this.#stopPointer = (e) => {
          if (this.#dialogBox.contains(e.target)) e.stopPropagation();
        };
        document.body.addEventListener("pointerdown", this.#stopPointer, true);

        // FIX 1: Focus the webview itself first so the browser hands over
        // keyboard control, then execute a script inside it to focus Todoist's
        // task-name input. The small delay lets the animation start and Todoist's
        // React tree settle before we try to focus.
        this.#webview.focus();
        setTimeout(() => {
          this.#webview.executeScript({
            code: `
              (function () {
                const sel = [
                  'input[data-testid]',
                  'textarea[data-testid]',
                  'div[contenteditable="true"]',
                  'input[placeholder]',
                  'textarea',
                  'input[type="text"]',
                ].join(',');
                const el = document.querySelector(sel);
                if (el) el.focus();
              })();
            `,
          });
        }, 150);
      });
    }

    #hideDialog() {
      if (!this.#visible) return;
      this.#visible = false;

      // Explicitly release focus from the Todoist webview immediately —
      // without this it holds keyboard focus even after being moved off-screen,
      // swallowing all shortcuts including Ctrl+Shift+A, Ctrl+L, Ctrl+E.
      this.#webview.blur();

      this.#dialogBox.style.animation =
        "todoist-dialog-out 0.15s cubic-bezier(0.2, 0.8, 0.2, 1) forwards";

      this.#dialogBox.addEventListener(
        "animationend",
        () => {
          this.#dialogContainer.style.left = "-99999px";
          this.#dialogContainer.style.pointerEvents = "none";
          this.#dialogBox.style.animation = "";
          // Reset to normal crop when dismissed so it opens clean next time.
          this.#dialogBox.style.clipPath = this.#clipCard();

          // FIX 2: Return focus to the active page so the user can type
          // immediately without having to click. Try a real tab webview first;
          // fall back to Vivaldi's #browser shell (covers the startpage and
          // any other non-webview context), then body as a last resort.
          // Delay so Vivaldi's internal focus management settles after the
          // container moves off-screen — without this, it steals focus back.
          setTimeout(() => {
            chrome.tabs.query({ active: true, currentWindow: true }, (tabs) => {
              console.log(
                "[Todoist] Active tab:",
                tabs?.[0]?.id,
                tabs?.[0]?.url,
              );
              console.log(
                "[Todoist] activeElement BEFORE:",
                document.activeElement?.tagName,
                document.activeElement?.id,
              );

              const tab = tabs?.[0];

              if (tab?.url === "vivaldi://startpage/") {
                const sdWrapper = document.getElementById("sdwrapper");
                console.log(
                  "[Todoist] Startpage detected, #sdwrapper found:",
                  !!sdWrapper,
                );
                if (sdWrapper) {
                  if (!sdWrapper.hasAttribute("tabindex"))
                    sdWrapper.setAttribute("tabindex", "-1");
                  sdWrapper.focus();
                  console.log(
                    "[Todoist] activeElement AFTER sdwrapper.focus():",
                    document.activeElement?.tagName,
                    document.activeElement?.id,
                  );
                  setTimeout(
                    () =>
                      console.log(
                        "[Todoist] activeElement AFTER sdwrapper 100ms:",
                        document.activeElement?.tagName,
                        document.activeElement?.id,
                      ),
                    100,
                  );
                  return;
                }
              }

              if (tab) {
                const activeWebview = document.getElementById(String(tab.id));
                console.log(
                  "[Todoist] Matched webview by tab ID:",
                  activeWebview ? `id=${activeWebview.id}` : "NOT FOUND",
                );
                if (activeWebview) {
                  activeWebview.focus();
                  console.log(
                    "[Todoist] activeElement AFTER webview.focus():",
                    document.activeElement?.tagName,
                    document.activeElement?.id,
                  );
                  setTimeout(
                    () =>
                      console.log(
                        "[Todoist] activeElement AFTER 100ms:",
                        document.activeElement?.tagName,
                        document.activeElement?.id,
                      ),
                    100,
                  );
                  return;
                }
              }

              const fallback =
                document.getElementById("browser") || document.body;
              console.log("[Todoist] Fallback:", fallback.tagName, fallback.id);
              fallback.focus();
              console.log(
                "[Todoist] activeElement AFTER fallback:",
                document.activeElement?.tagName,
                document.activeElement?.id,
              );
            });
          }, 50);
        },
        { once: true },
      );

      if (this.#stopPointer) {
        document.body.removeEventListener(
          "pointerdown",
          this.#stopPointer,
          true,
        );
        this.#stopPointer = null;
      }
    }

    #onKeyCombo(_id, combination) {
      if (combination === "Ctrl+Shift+A") {
        this.#visible ? this.#hideDialog() : this.#showDialog();
      } else if (combination === "Esc" && this.#visible) {
        this.#hideDialog();
      }
    }
  }
})();
