#!/usr/bin/env bash
# Build the Docker image for Flexiv Elements Studio. This script should be run from the root of the repository.

# Check if package exists
if [ ! -d "package/FlexivElementsStudio" ]; then
    echo "Error: FlexivElementsStudio directory is not found under package/ directory, please refer to README.md."
    exit 1
fi

# Prompt interactively for the tag
read -p "Please enter the tag for the image, for example v3.11: " TAG
if [ -z "$TAG" ]; then
    echo "Error: Tag cannot be empty."
    exit 1
fi

# Prompt interactively for which physics engine to use
echo "Please choose which physics engine to use for simulation:"
echo "[1] Built-in"
echo "[2] External"
read -p "Enter choice [1/2]: " PHYSICS_CHOICE

# Switch physics engine based on user choice
(
    cd package/FlexivElementsStudio || exit 1
    if [ "$PHYSICS_CHOICE" = "1" ] || [ "$PHYSICS_CHOICE" = "2" ]; then
        echo "$PHYSICS_CHOICE" | bash switch_physics_engine.sh
    else
        echo "Error: Invalid choice."
        exit 1
    fi
) || exit 1

# Build the image
docker build -f docker/Dockerfile_FlexivElementsStudio -t flexiv-elements-studio:"$TAG" .

# Done, ask if exporting the image as tarball is needed
read -p "Do you want to export the image as a tarball? (y/N) " EXPORT_ANSWER
if [[ "$EXPORT_ANSWER" =~ ^[Yy]$ ]]; then
    # Save tarball to export/ directory
    OUTPUT_FILE="export/flexiv-elements-studio-${TAG}.tar"
    docker save -o "$OUTPUT_FILE" "flexiv-elements-studio:${TAG}"
    echo "Image exported to $OUTPUT_FILE"
else
    echo "Image build complete. Please refer to README.md for how to run the container."
fi