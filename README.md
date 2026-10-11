# XFCE Desktop in GitHub Codespaces

A lightweight XFCE Linux desktop accessible through a web browser using
TigerVNC and noVNC. NoVNC provides browser access without requiring a local
VNC client.

## Features

- XFCE desktop environment
- Browser-based access through noVNC
- TigerVNC server
- Desktop resolution configured as `1366x768`
  - TigerVNC may report the actual resolution as `1368x768`.
- Docker-based development container
- Private forwarded port for browser access

## Repository Structure

```text
.
├── .devcontainer/
│   ├── devcontainer.json
│   └── start-desktop.sh
├── Dockerfile
└── README.md
```

## 1. Create a Codespace

1. Open this repository on GitHub.
2. Select **Code → Codespaces**.
3. Create a new Codespace on the `main` branch.
4. Wait for the development container to finish building.

The Dockerfile installs XFCE, TigerVNC, noVNC, and their required
dependencies.

## 2. First-Time Setup

Open the Codespace terminal.

### Configure a VNC password

```bash
vncpasswd
```

Choose a password and keep it somewhere safe. You will need it whenever
you connect to the desktop.

The password file is stored at:

```text
~/.vnc/passwd
```

### Back up the password file

The repository's startup script can restore the password from a backup
if the home-directory password file is missing.

```bash
mkdir -p /workspaces/.codespace-secrets
cp ~/.vnc/passwd /workspaces/.codespace-secrets/vnc-passwd
chmod 600 /workspaces/.codespace-secrets/vnc-passwd
```

Keep this backup private. Never commit it to GitHub.

## 3. Start the Desktop

Automatic startup may not work reliably in every Codespaces restart.
The reliable fallback is to start the desktop manually.

From the repository root, run:

```bash
bash .devcontainer/start-desktop.sh
```

The script configures the XFCE session, checks for a VNC password,
starts TigerVNC on display `:1`, and launches noVNC on port `6080`.

If startup succeeds, noVNC should be available on port `6080`.

## 4. Open XFCE in Your Browser

1. Open the **Ports** tab in VS Code or the Codespaces interface.
2. Find port `6080`.
3. If necessary, set its visibility to **Private**.
4. Click **Open in Browser**.
5. Click **Connect** in noVNC.
6. Enter the VNC password.

The VNC server itself listens on localhost port `5901`. Browser access
is provided through noVNC on port `6080`.

Do not expose the VNC port publicly.

## 5. What to Do After Stopping and Restarting a Codespace

After resuming a stopped Codespace:

1. Wait for the Codespace to finish starting.
2. Open the forwarded address for port `6080`.
3. If the page returns HTTP 502, open the Codespace terminal.
4. From the repository root, run:

   ```bash
   bash .devcontainer/start-desktop.sh
   ```

5. Wait for the command to finish, then reload the browser page.

If the desktop is already running, the script should avoid starting another
VNC server. If noVNC is not listening, the script should attempt to launch it.

## 6. Check the Services

To check whether VNC and noVNC are listening:

```bash
ss -ltn | grep -E ':5901|:6080'
```

Expected listeners include:

- `127.0.0.1:5901` — VNC server
- `0.0.0.0:6080` — noVNC browser gateway

To check the related processes:

```bash
pgrep -af 'Xtigervnc|novnc_proxy|websockify' || true
```

To inspect the noVNC log:

```bash
tail -50 ~/.vnc/novnc.log
```

To inspect the startup log:

```bash
tail -50 /tmp/desktop-startup.log
```

## 7. Common Problems

### HTTP 502 on port 6080

This usually means the forwarded port is available in Codespaces but
the noVNC service is not listening.

Run:

```bash
bash .devcontainer/start-desktop.sh
```

Then reload the forwarded address.

### VNC password missing

If the script reports that the VNC password is missing, restore it from
the backup if that backup exists:

```bash
cp /workspaces/.codespace-secrets/vnc-passwd ~/.vnc/passwd
chmod 600 ~/.vnc/passwd
```

If no backup exists, configure a new password:

```bash
vncpasswd
```

Then start the desktop again.

### Display `:1` is already running

If the script reports that display `:1` is already running, first check
whether the VNC process exists:

```bash
pgrep -af Xtigervnc
```

Do not delete X11 lock files while a VNC server is running.

If no VNC process exists but stale lock files remain, remove the stale
files and try starting the desktop again:

```bash
rm -f /tmp/.X11-unix/X1 /tmp/.X1-lock
```

### Port 6080 is not listening

Check the VNC process, then run the startup script again:

```bash
bash .devcontainer/start-desktop.sh
```

Inspect `~/.vnc/novnc.log` if noVNC still fails.

## 8. Container Rebuilds

A container rebuild can affect files in the home directory and temporary
runtime state. Before rebuilding:

- Make sure you have a private backup of the VNC password file.
- Never add password files to Git.
- After rebuilding, verify that the password file exists.
- Run the startup script manually if the services do not start automatically.

The backup under `/workspaces/.codespace-secrets` is outside the repository,
but it should not be treated as a guaranteed permanent secret store.

## 9. Configuration

The development container configuration is in
`.devcontainer/devcontainer.json`.

The Docker image and installed packages are defined in `Dockerfile`.

The desktop startup logic is defined in `.devcontainer/start-desktop.sh`.

The forwarded browser-access port is `6080`; the internal VNC port is `5901`.

## Security Notes

- Use a strong VNC password.
- Keep port `6080` private to your Codespace unless you have a specific
  reason to change its visibility.
- Do not commit VNC passwords, password backups, tokens, or other secrets.
- Codespaces may stop when idle, and forwarded addresses may be unavailable
  while the Codespace is stopped.
