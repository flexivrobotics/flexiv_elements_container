#!/usr/bin/env bash
# ==============================================================================
# Script: run_elements_in_container.sh
# Description: Runs or manages Flexiv Elements inside a Docker container.
#
# Features:
#   1. Interactive Docker image tag selection.
#   2. X11 socket and authority forwarding (XAuthority) for GUI applications.
#   3. Wayland display socket forwarding (if available on the host).
#   4. GPU device exposure (/dev/dri) to ensure OpenGL and Qt stability.
#   5. Scan for existing containers instantiated from the same image:
#      - Lists them with their current status.
#      - Offers an interactive menu to restart/attach to an existing container,
#        or spin up a brand new one.
#   6. Uses randomized Docker container names for new containers to allow multiple
#      parallel or distinct instances without conflicts.
#   7. Post-execution watch to ensure the container is safely stopped.
# ==============================================================================

# Prompt interactively for the tag
read -p "Please enter the tag for the [flexiv-elements] Docker image to use: " TAG
if [ -z "$TAG" ]; then
    echo "Error: Tag cannot be empty."
    exit 1
fi

# Setup X11 authentication
# This ensures that GUI applications running inside the container can authenticate
# and display on the host's X server.
XAUTH_MOUNT=""
if [ -n "$XAUTHORITY" ]; then
    XAUTH_MOUNT="-v $XAUTHORITY:$XAUTHORITY:ro -e XAUTHORITY=$XAUTHORITY"
elif [ -f "$HOME/.Xauthority" ]; then
    XAUTH_MOUNT="-v $HOME/.Xauthority:/root/.Xauthority:ro -e XAUTHORITY=/root/.Xauthority"
fi

# Setup Wayland socket forwarding (if supported by host)
# If the host system runs Wayland, we share the socket and guide Qt to use it.
WAYLAND_MOUNT=""
if [ -n "$WAYLAND_DISPLAY" ] && [ -n "$XDG_RUNTIME_DIR" ]; then
    WAYLAND_MOUNT="-v $XDG_RUNTIME_DIR/$WAYLAND_DISPLAY:/tmp/$WAYLAND_DISPLAY \
                   -e WAYLAND_DISPLAY=$WAYLAND_DISPLAY \
                   -e XDG_RUNTIME_DIR=/tmp"
fi

# Setup GPU access (if available) for Qt/OpenGL stability
# Passing direct graphics rendering devices facilitates hardware-accelerated rendering.
GPU_DEVICES=""
if [ -c /dev/dri ]; then
    GPU_DEVICES="--device /dev/dri"
fi

IMAGE="flexiv-elements:${TAG}"

# Get list of existing containers for this image
# We scan both active and stopped containers that use the targeted image.
containers=()
while IFS= read -r line; do
    if [ -n "$line" ]; then
        containers+=("$line")
    fi
done < <(docker ps -a --filter "ancestor=${IMAGE}" --format '{{.Names}}')

CONTAINER_NAME=""

# Display the interactive selection menu if one or more matching containers are found
if [ ${#containers[@]} -gt 0 ]; then
    echo "Found existing container(s) for image ${IMAGE}:"
    for i in "${!containers[@]}"; do
        status=$(docker inspect -f '{{.State.Status}}' "${containers[i]}")
        echo "[$((i+1))] Restart container [${containers[i]}] (status: ${status})"
    done
    echo "[$(( ${#containers[@]} + 1 ))] Create a new container (with a random name)"
    
    while true; do
        read -p "Choose an option [1-$(( ${#containers[@]} + 1 ))]: " choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le $(( ${#containers[@]} + 1 )) ]; then
            break
        else
            echo "Invalid choice. Please try again."
        fi
    done
    
    if [ "$choice" -ne $(( ${#containers[@]} + 1 )) ]; then
        CONTAINER_NAME="${containers[$((choice-1))]}"
    fi
fi

if [ -n "${CONTAINER_NAME}" ]; then
    # Start and attach to the chosen existing container
    echo "Starting and attaching to existing container ${CONTAINER_NAME}..."
    docker start -ai "${CONTAINER_NAME}"
else
    # Create a brand-new container with a random name assigned by docker
    echo "Creating and running new container..."
    CONTAINER_ID=$(docker create --device /dev/fuse --cap-add SYS_ADMIN --ipc=host \
               -e DISPLAY=$DISPLAY \
               $XAUTH_MOUNT \
               $WAYLAND_MOUNT \
               $GPU_DEVICES \
               --security-opt apparmor:unconfined \
               -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
               flexiv-elements:${TAG})
    CONTAINER_NAME=$(docker inspect -f '{{.Name}}' "${CONTAINER_ID}" | sed 's/^\///')
    echo "Created container: ${CONTAINER_NAME}"
    docker start -ai "${CONTAINER_ID}"
fi

# Double check if the container is stopped after exiting, force stop if it is still running
# This acts as a fallback to prevent dangling container processes.
if [ -n "${CONTAINER_NAME}" ]; then
    if docker inspect "${CONTAINER_NAME}" >/dev/null 2>&1; then
        if [ "$(docker inspect -f '{{.State.Running}}' "${CONTAINER_NAME}")" = "true" ]; then
            echo "Warning: Container ${CONTAINER_NAME} is still running after exiting. Forcing stop..."
            docker stop "${CONTAINER_NAME}"
        fi
    fi
fi