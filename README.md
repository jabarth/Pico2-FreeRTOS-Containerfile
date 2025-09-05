# Pico2-FreeRTOS-Containerfile
9/5/2025 - For a Pico 2 with FreeRTOS official repo build.  This repo houses a basic boilerplate 'Hello World' blinky example...in morse code.   It is a straightforward Containerfile, implementing heredocs for simple portability and readabilty.  A picotool w/ LIBUSB is also built inline for reuse.

## Building the Images

To build the images, use the `podman build` command. Here are some examples for each target:

### picotool

This image contains the `picotool` executable and the Pico SDK.

```bash
podman build -f Containerfile --target picotool -t picotool:latest .
```

### freertos-builder

This image contains the FreeRTOS build environment and the compiled firmware.

```bash
podman build -f Containerfile --target freertos-builder -t freertos-builder:latest .
```

### freertos-firmware-uf2

This image contains only the `morse-blink.uf2` firmware file.

```bash
podman build -f Containerfile --target freertos-firmware-uf2 -t freertos-firmware-uf2:latest .
```

To extract the firmware from the `freertos-firmware-uf2` image, you can use the following command:

```bash
podman build -f Containerfile --target freertos-firmware-uf2 --output .
```
This will copy the `firmware.uf2` file to your current directory.
