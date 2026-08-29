# A Bootable Rudimentary Tunnel-Effect 3D Raycaster in 16-bit x86 Assembly (VGA 320×200)

A small, bootable 16-bit x86 assembly program that implements a rudimentary 3D tunnel effect using ray casting and VGA Mode 13h (320×200, 256 colors).

## Building and Running

You need:

- [NASM](https://www.nasm.us/) to assemble the program
- `dd` (or an equivalent tool) to create the bootable floppy image
- [QEMU](https://www.qemu.org/) or [VirtualBox](https://www.virtualbox.org/) to run it

Build the bootable image:

```bash
nasm -f bin raycast.asm -o raycast
dd conv=notrunc bs=4096 count=1 if=raycast of=raycast.img
```

Run it with QEMU:
```bash
qemu-system-i386 -fda raycast.img
```

# VGA display and tunnel rendering

## VGA mode and framebuffer layout

We use VGA 320×200 mode (`140h × 0C8h`), with pixels stored in memory starting at `VGA_ADDR = A000h:0000`.

- `(x, y) = (0, 0)` — top-left pixel: `VGA_ADDR`
- `(x, y) = (319, 0)` — top-right pixel: `VGA_ADDR + 319`
- `(x, y) = (0, 199)` — bottom-left pixel: `VGA_ADDR + 320 × 199`
- `(x, y) = (319, 199)` — bottom-right pixel:
  `VGA_ADDR + 320 × 199 + 319 = VGA_ADDR + 320 × 200 − 1`

The VGA palette is configured with 63 grayscale colors (`0–63`). Colors `64–255` are set to light blue and represent the sky.

## Camera and coordinate system

We assume that the camera is located at the center of the screen:
`(x, y) = (160, 100)`

The camera is positioned at depth `z = 0`, with depth increasing as we look further into the screen.

For each pixel, we calculate its horizontal and vertical distance from the camera:

- `xdist = |x − 160|`
- `ydist = |y − 100|`

These distances determine how quickly the corresponding ray reaches one of the tunnel walls.

## Ray casting

For each pixel, we cast a ray from the camera into the tunnel by incrementing `z`, starting at `z = 1`.

At each depth, we evaluate:

- `z × xdist` — distance toward the horizontal direction of the tunnel walls
- `z × ydist` — distance toward the vertical direction of the tunnel walls

A wall is reached when either value exceeds a predefined threshold `t`:
`z × xdist > t` or `z × ydist > t`

We continue increasing `z` until either:

1. A wall is reached, or
2. `z` reaches the maximum value of `255`.

If `z = 255` is reached without hitting a wall, the ray has traveled all the way to the end of the tunnel. We therefore color the pixel light blue, representing the sky visible through the end of the tunnel.

Otherwise, the ray hits a wall at depth `z`, and we color the pixel with a grayscale value proportional to `z`.

## Why the tunnel looks illuminated

The resulting image represents a tunnel with a bright blue sky visible at its far end. Walls that are close to the end of the tunnel appear brighter because they are closer to the light coming from the sky.

Pixels near the center of the screen have small `xdist` and `ydist` values. Consequently, `z × xdist` and `z × ydist` grow more slowly, requiring a larger `z` to reach the threshold. These rays can therefore travel farther into the tunnel and may reach `z = 255`, revealing the blue sky.

Pixels farther from the center have larger `xdist` and/or `ydist` values. Their products with `z` reach the threshold more quickly, so they hit the tunnel walls at a smaller depth.

In other words:

- Far from the center: large `xdist`/`ydist` → wall is reached quickly → smaller `z`
- Near the center: small `xdist`/`ydist` → ray travels farther → larger `z` → potentially reaches the sky

The tunnel depth can be controlled with the keyboard. The Up and Down arrow keys increase or decrease the threshold `t`, effectively moving the camera forward or backward through the tunnel.
