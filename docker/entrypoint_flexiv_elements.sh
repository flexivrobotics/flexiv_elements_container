#!/bin/sh
set -eu

APP_DIR=/workdir
APP_BIN="$APP_DIR/FlexivElements"

export LD_LIBRARY_PATH="$APP_DIR/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export QT_QPA_PLATFORM_PLUGIN_PATH="$APP_DIR/plugins"
export QTWEBENGINE_DISABLE_SANDBOX="${QTWEBENGINE_DISABLE_SANDBOX:-1}"

if [ -z "${DISPLAY:-}" ] && [ -z "${WAYLAND_DISPLAY:-}" ]; then
    echo "Neither DISPLAY nor WAYLAND_DISPLAY is set. Start the container with the host X11 or Wayland socket mounted and pass the display variable through." >&2
    exit 1
fi

if [ ! -x "$APP_BIN" ]; then
    echo "Expected executable not found: $APP_BIN" >&2
    exit 1
fi

# Detect and resolve potential port collisions for multiple run instances on host network
# Shift all ports (excluding AIPC) by an offset if port 17002 is occupied
PORT_OFFSET=0
MAIN_COMM_CONF="$APP_DIR/user_data_ui/settings/commCfg.prototxt"
if command -v netstat >/dev/null 2>&1; then
    if [ -f "$MAIN_COMM_CONF" ] && netstat -tuln | grep -E -q "[:.]17002([^0-9]|$)"; then
        echo "Port 17002 is already bound on the host. Finding slot allocation..."
        for offset in $(seq 100 100 10000); do
            # Test if the offset target port (17002 + offset) is free
            target_port=$((17002 + offset))
            if ! netstat -tuln | grep -E -q "[:.]${target_port}([^0-9]|$)"; then
                PORT_OFFSET=$offset
                break
            fi
        done
    fi
fi

# Apply port shifts to the current container's configuration files (except under AIPC blocks)
if [ "$PORT_OFFSET" -ne 0 ]; then
    echo "Applying port shift offset (+${PORT_OFFSET}) to current container's configs..."
    # Offset ports in master UI config and standard template directories (excluding lines falling within AIPC)
    for conf in "$MAIN_COMM_CONF" "$APP_DIR/userDataTemplate/settings/commCfg.prototxt"; do
        if [ -f "$conf" ]; then
            # Use awk to parse and offset ports for sections outside pc { name: "AIPC" ... }
            awk -v offset="$PORT_OFFSET" '
                BEGIN { in_aipc = 0; brace_depth = 0 }
                /pc \{/ { brace_depth++ }
                /name: "AIPC"/ { if (brace_depth == 1) in_aipc = 1 }
                /port: "[0-9]+"/ {
                    if (!in_aipc) {
                        match($0, /"[0-9]+"/)
                        if (RSTART > 0) {
                            p_val = substr($0, RSTART+1, RLENGTH-2)
                            new_port = p_val + offset
                            sub(/"[0-9]+"/, "\"" new_port "\"")
                        }
                    }
                }
                /\}/ {
                    brace_depth--
                    if (brace_depth == 0) in_aipc = 0
                }
                { print }
            ' "$conf" > "${conf}.tmp" && mv "${conf}.tmp" "$conf"
        fi
    done
fi

# Synced copy task to mirror UI_COMM_CONF directly to all existing and newly created simulator directories
sync_simulators() {
    # Sync existing simulator configs on startup
    find "$APP_DIR/user_data_ui/simDir" -type d -name "settings" 2>/dev/null | while IFS= read -r settings_dir; do
        if [ -f "$MAIN_COMM_CONF" ]; then
            cp -f "$MAIN_COMM_CONF" "$settings_dir/commCfg.prototxt"
        fi
    done

    # Use event-driven watcher to trigger sync on simulator directory creation immediately
    echo "Starting event-driven inotify watch on simulator directory..."
    inotifywait -m -e create,moved_to --format '%f' "$APP_DIR/user_data_ui/simDir" 2>/dev/null | while IFS= read -r name; do
        if [ -f "$MAIN_COMM_CONF" ]; then
            case "$name" in
                simulator*)
                    (
                        # Wait briefly for directory structure to be created
                        sleep 0.2
                        settings_dir="$APP_DIR/user_data_ui/simDir/$name/settings"
                        mkdir -p "$settings_dir"
                        cp -f "$MAIN_COMM_CONF" "$settings_dir/commCfg.prototxt"
                        echo "Inotify: Synced config to new simulator directory: $settings_dir/commCfg.prototxt"
                    ) &
                    ;;
            esac
        fi
    done
}

# Start background sync watcher
sync_simulators &

cd "$APP_DIR"
exec "$APP_BIN" -p ubuntu_pc "$@"
