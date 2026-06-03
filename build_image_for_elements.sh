#!/usr/bin/env bash
# Build the Docker image for Flexiv Elements. This script should be run from the root of the repository.

# Check if package exists
if [ ! -d "package/FlexivElements" ]; then
    echo "Error: FlexivElements directory is not found under package/ directory, please refer to README.md."
    exit 1
fi

# Prompt interactively for the tag
read -p "Please enter the tag for the image, for example v3.11: " TAG
if [ -z "$TAG" ]; then
    echo "Error: Tag cannot be empty."
    exit 1
fi

# Build the image
docker build -f docker/Dockerfile_FlexivElements -t flexiv-elements:"$TAG" .

# Done, ask if exporting the image as tarball is needed
read -p "Do you want to export the image as a tarball? (y/N) " EXPORT_ANSWER
if [[ "$EXPORT_ANSWER" =~ ^[Yy]$ ]]; then
    # Save tarball to export/ directory
    OUTPUT_FILE="export/flexiv-elements-${TAG}.tar"
    docker save -o "$OUTPUT_FILE" "flexiv-elements:${TAG}"
    echo "Image exported to $OUTPUT_FILE"
else
    echo "Image build complete. Please refer to README.md for how to run the container."
fi