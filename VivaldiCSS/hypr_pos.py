# created with Claude. Account: Milobowler

import http.server
import json
import subprocess
import threading
import time

# ---------------------------------------------------------------------------
# Shared state
# ---------------------------------------------------------------------------

ui_offset = {"left": 0, "top": 0}

# Pre-computed response — background thread writes this, HTTP handler reads it.
# Serving a cached value means the HTTP response is instant (no subprocess wait).
cached_pos = None
state_lock  = threading.Lock()

# ---------------------------------------------------------------------------
# Background poller — runs hyprctl on its own thread at ~60fps
# ---------------------------------------------------------------------------

def poll_hyprland():
    global cached_pos

    # Monitors change rarely — fetch once at startup and reuse.
    # If you hotplug a monitor, restart the script.
    monitors = json.loads(subprocess.check_output(['hyprctl', 'monitors', '-j']))

    while True:
        try:
            clients = json.loads(subprocess.check_output(['hyprctl', 'clients', '-j']))

            win = next(
                (c for c in clients if c.get('class', '').lower().startswith('vivaldi')),
                None
            )

            if win:
                active_mon = next(m for m in monitors if m['id'] == win['monitor'])

                with state_lock:
                    offset = ui_offset.copy()

                pos = {
                    "bgX": (win['at'][0] - active_mon['x']) + offset['left'],
                    "bgY": (win['at'][1] - active_mon['y']) + offset['top'],
                    "monW": active_mon['width'],
                    "monH": active_mon['height']
                }

                with state_lock:
                    cached_pos = pos

        except Exception:
            pass  # hyprctl blip — keep the last cached value, try again next tick

        time.sleep(1 / 60)  # ~60fps


# ---------------------------------------------------------------------------
# HTTP handler — serves the cached value instantly, no subprocess blocking
# ---------------------------------------------------------------------------

class Handler(http.server.BaseHTTPRequestHandler):

    def log_message(self, format, *args):
        pass

    def _cors(self):
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')

    def do_OPTIONS(self):
        self.send_response(200)
        self._cors()
        self.end_headers()

    def do_POST(self):
        if self.path == '/offset':
            length   = int(self.headers.get('Content-Length', 0))
            raw      = self.rfile.read(length)
            try:
                data = json.loads(raw)
                with state_lock:
                    ui_offset.update(data)
                self.send_response(200)
            except json.JSONDecodeError:
                self.send_response(400)
            self._cors()
            self.end_headers()

    def do_GET(self):
        if self.path == '/wallpaper':
            try:
                with open('/home/shayan/.mydotfiles/com.ml4w.hyprlandstarter/.config/ml4w/wallpapers/wallpaper.jpg', 'rb') as f:
                    body = f.read()
                self.send_response(200)
                self.send_header('Content-Type', 'image/jpeg')
                self.send_header('Content-Length', str(len(body)))
                self._cors()
                self.end_headers()
                self.wfile.write(body)
            except Exception:
                self.send_response(404)
                self._cors()
                self.end_headers()
            return


        if self.path == '/pos':
            with state_lock:
                pos = cached_pos

            if pos is None:
                self.send_response(503)  # Not ready yet
                self._cors()
                self.end_headers()
                return

            body = json.dumps(pos).encode()
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Content-Length', str(len(body)))
            self._cors()
            self.end_headers()
            self.wfile.write(body)


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

if __name__ == '__main__':
    t = threading.Thread(target=poll_hyprland, daemon=True)
    t.start()
    print("Hyprland Bridge running on http://localhost:12345 ...")
    http.server.HTTPServer(('localhost', 12345), Handler).serve_forever()
