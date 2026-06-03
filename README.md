# Flexiv Elements Containers

Tools to create Docker images for Flexiv Elements and Flexiv Elements Studio so multiple instances can run on the same computer using Docker containers.

---

## Supported Host

Currently, only **Ubuntu 22.04** is tested as the host operating system.

## Quick Start Guide

### 1. Prerequisites

Ensure you have **Docker** installed and configured to run without `sudo` (non-root user access).

### 2. Preparation

Place your Flexiv installation folders under the `package/` directory:

- For **Elements**: `package/FlexivElements/`
- For **Elements Studio**: `package/FlexivElementsStudio/`

Make sure there's no nested root directories like `FlexivElements/FlexivElements_v3.11/`.

### 3. Build Docker Image

Run the script corresponding to the application you want to pack:

- **For Flexiv Elements:**

  ```bash
  ./build_image_for_elements.sh
  ```

- **For Flexiv Elements Studio:**

  ```bash
  ./build_image_for_elements_studio.sh
  ```

_Follow the interactive prompts to define the image tag and toggle options (such as selecting a physics engine or exporting the image as a tarball)._

### 4. Run Container

Launch the container by running the respective script. You can pass the tag as an argument, or leave it blank to be prompted:

- **For Flexiv Elements:**

  ```bash
  ./run_elements_in_container.sh <tag>
  ```

- **For Flexiv Elements Studio:**

  ```bash
  ./run_elements_studio_in_container.sh <tag>
  ```

---

## Host Network Mode

The containers are configured to use the host network (`--network host`). This allows programs running inside the container (e.g. Flexiv Elements, the simulated robots, etc.) to communicate natively and with low-latency with programs on the host or other machines, such as **NVIDIA Isaac Sim**, **Flexiv RDK**, and **Flexiv TDK**.

---

## Advanced Management

The execution scripts automatically handle:

- **GUI & Display Forwarding**: X11 authority and Wayland support are mounted to display GUIs seamlessly.
- **GPU Acceleration**: Passes `/dev/dri` to ensure OpenGL stability.
- **Multi-Instance Management**: Scans for existing containers from the same image and provides an option to restart/attach to an existing one or start a brand new randomized container.
