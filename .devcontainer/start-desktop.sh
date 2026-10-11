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

# Restore the VNC password after a container rebuild if needed.
if [ ! -s "$HOME/.vnc/passwd" ] && [ -s /workspaces/.codespace-secrets/vnc-passwd ]; then
  cp /workspaces/.codespace-secrets/vnc-passwd "$HOME/.vnc/passwd"
  chmod 600 "$HOME/.vnc/passwd"
fi

# A VNC password must be configured before starting the desktop.
if [ ! -s "$HOME/.vnc/passwd" ]; then
  echo "VNC password missing. Run: vncpasswd"
  exit 1
fi

# Start VNC only if display :1 is not already running.
if ! pgrep -f '^/usr/bin/Xtigervnc :1 ' >/dev/null; then
  rm -f /tmp/.X11-unix/X1 /tmp/.X1-lock "$HOME/.vnc/"*":1.pid"
  vncserver :1 -localhost yes -geometry 1366x768 -depth 24
fi

# Start noVNC only if port 6080 is not already listening.
if ! ss -ltn | grep -q ':6080'; then
  setsid /usr/share/novnc/utils/novnc_proxy \
    --listen 0.0.0.0:6080 \
    --vnc localhost:5901 \
    > "$HOME/.vnc/novnc.log" 2>&1 < /dev/null &
fi
