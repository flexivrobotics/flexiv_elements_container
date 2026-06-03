#!/bin/sh
set -eu

APP_DIR=/workdir
APP_BIN="$APP_DIR/FlexivElements"

export LD_LIBRARY_PATH="$APP_DIR/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export QT_QPA_PLATFORM_PLUGIN_PATH="$APP_DIR/plugins"
export QTWEBENGINE_DISABLE_SANDBOX="${QTWEBENGINE_DISABLE_SANDBOX:-1}"

if [ -z "${DISPLAY:-}" ]; then
    echo "DISPLAY is not set. Start the container with the host X11 socket mounted and pass DISPLAY through." >&2
    exit 1
fi

if [ ! -x "$APP_BIN" ]; then
    echo "Expected executable not found: $APP_BIN" >&2
    exit 1
fi

cd "$APP_DIR"
exec "$APP_BIN" -p ubuntu_pc "$@"
