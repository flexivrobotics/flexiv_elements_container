#!/usr/bin/env bash
# Run Flexiv Elements in Docker container.

# Prompt interactively for the tag
read -p "Please enter the tag for the image to load, for example v3.11: " TAG
if [ -z "$TAG" ]; then
    echo "Error: Tag cannot be empty."
    exit 1
fi

docker run --rm --device /dev/fuse --cap-add SYS_ADMIN -e DISPLAY=$DISPLAY \
           --security-opt apparmor:unconfined \
           -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
           --name "flexiv-elements-${TAG}-$(date +%s)" \
           flexiv-elements:${TAG}