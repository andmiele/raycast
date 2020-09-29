## A rudimentary bootable tunnel effect 3d raycaster in 16-bit x86 assembly (VGA 320x200)
# Instructions
You need the NASM assembler to compile it and a tool like dd to create a bootable floppy image and either QEMU or VirtualBox to run it:

1. ./nasm -bin raycast.m -o raycast
2. ./dd conv=notrunc bs=4096 count=1 if=raycast of=raycast.img
3. ./qemu-system-i386 -fda raycast.img

# Description
VGA 320x200 (140h x 0c8h) mode, pixels stored in memory starting at address VGA_ADDR = A000h:0000

x,y = 0,0 top-left pixel, VGA_ADDR 

x,y = 319,0 top-right pixel, VGA_ADDR + 319

x,y = 0,199 bottom-left pixel  VGA_ADDR + `320*199`

x,y = 319,199 bottom-right pixel  VGA_ADDR + `320*199` + 319 = `320*200 -1`

We set the VGA palette to 63 grayscale colors and colors 64 to 256 are set to light blue for the sky.

We assume that the camera is positioned at about the center of the screen x, y = 160, 100.

We assume that the camera (center of the screen) is positioned at depth z = 0 and that depth z increases as we move down into the screen.

For each pixel we compute vertical (ydist) and horizontal (xdist) distance from the camera (x,y = 160, 100).

The distance to a vertical (horizontal) wall is proportional to the product between depth z and ydist (xdist).

For each pixel we increase z (starting from 1) until `z*xdist` or `z*ydist` is larger than a certain threshold t or z reaches a maximum value (255). If z reaches 255 it means that we can see the sky through that pixel (light blue color).

Otherwise we hit a wall and the pixel is colored with a grayscale tone proportional to z.

The idea is that at the end of the tunnel we have the bright blue sky and the closer the wall sides are to the end the brighter we see them as they get more light from the outside.

For each pixel we are essentially casting a ray from the camera (by increasing z) going through the pixel until it reaches a wall or reaches maximum distance without touching one.  But we do this by simply increasing the xdist along the x axis  (`z*xdist`) and the ydist along the y axis (`z*ydist`) as z increases. The further away from the center we move along the x or y axis the closer we get to a wall (if the distance is larger than the threshold we have hit a wall).The further away we look from the center (the larger xdist and ydist) the smaller z is needed to make `xdist*z` and `ydist*z` exceed the threshold (a wall is hit).

The closer to the center we look (the smaller xdist and ydist) the larger z is needed to make `xdist*z` and `ydist*z` exceed the threshold and it might happen that z reaches its maximum before that happening (in which case we see the sky at the end of the tunnel).
We use keyboard up and down arrows to move along the tunnel (by increasing or decreasing the threshold t).
