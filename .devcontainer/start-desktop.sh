#!/usr/bin/env bash
set -euo pipefail

mkdir -p "$HOME/.vnc"

# Configure XFCE as the VNC desktop session.
cat > "$HOME/.vnc/xstartup" <<'STARTUP'
#!/bin/sh
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
exec dbus-launch --exit-with-session startxfce4
STARTUP
chmod +x "$HOME/.vnc/xstartup"

# A VNC password must be configured before starting the desktop.
if [ ! -s "$HOME/.vnc/passwd" ]; then
  echo "VNC password missing. Run: vncpasswd"
  exit 1
fi

# Start VNC only if display :1 is not already running.
if ! pgrep -f '^/usr/bin/Xtigervnc :1 ' >/dev/null; then
  vncserver :1 -localhost yes -geometry 1366x768 -depth 24
fi

# Start noVNC only if port 6080 is not already listening.
if ! ss -ltn | grep -q ':6080'; then
  nohup /usr/share/novnc/utils/novnc_proxy \
    --listen 0.0.0.0:6080 \
    --vnc localhost:5901 \
    > "$HOME/.vnc/novnc.log" 2>&1 < /dev/null &
fi
