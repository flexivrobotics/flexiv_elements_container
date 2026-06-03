#!/usr/bin/env bash
# Run Flexiv Elements in Docker container.

# Prompt interactively for the tag
read -p "Please enter the tag for the image to load, for example v3.11: " TAG
if [ -z "$TAG" ]; then
    echo "Error: Tag cannot be empty."
    exit 1
fi

# Setup X11 authentication
XAUTH_MOUNT=""
if [ -n "$XAUTHORITY" ]; then
    XAUTH_MOUNT="-v $XAUTHORITY:$XAUTHORITY:ro -e XAUTHORITY=$XAUTHORITY"
elif [ -f "$HOME/.Xauthority" ]; then
    XAUTH_MOUNT="-v $HOME/.Xauthority:/root/.Xauthority:ro -e XAUTHORITY=/root/.Xauthority"
fi

# Setup Wayland socket forwarding (if supported by host)
WAYLAND_MOUNT=""
if [ -n "$WAYLAND_DISPLAY" ] && [ -n "$XDG_RUNTIME_DIR" ]; then
    WAYLAND_MOUNT="-v $XDG_RUNTIME_DIR/$WAYLAND_DISPLAY:/tmp/$WAYLAND_DISPLAY \
                   -e WAYLAND_DISPLAY=$WAYLAND_DISPLAY \
                   -e XDG_RUNTIME_DIR=/tmp"
fi

# Setup GPU access (if available) for Qt/OpenGL stability
GPU_DEVICES=""
if [ -c /dev/dri ]; then
    GPU_DEVICES="--device /dev/dri"
fi

docker run --rm --device /dev/fuse --cap-add SYS_ADMIN --ipc=host \
           -e DISPLAY=$DISPLAY \
           $XAUTH_MOUNT \
           $WAYLAND_MOUNT \
           $GPU_DEVICES \
           --security-opt apparmor:unconfined \
           -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
           --name "flexiv-elements-${TAG}-$(date +%s)" \
           flexiv-elements:${TAG}