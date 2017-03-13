[bits 16]       ; 16-bit mode
[org 0x7C00]    ; bootloader load address

jmp 0x0000:boot ; cs = 0x0000

;initialize segment registers

boot:
xor ax, ax
mov ds, ax
mov es, ax

; read one sector from disk

mov ah, 0x00 ; reset disk drive
mov dl, 0x0    ; first floppy drive
int 0x13    ; BIOS interrupt 0x13

; read sectors from drive BIOS interrupt 0x13

mov ah, 0x02 ; read sectors from drive
mov al, 1    ; read 1 secor
mov dl, 0    ; drive number
mov ch, 0    ; cylinder number
mov dh, 0    ; head number
mov cl, 2    ; start from sector 2, skip bootloader sector
mov bx, main ; address to store sector
int 0x13     ; call BIOS interrupt 0x13
jmp main     ; jump to loaded code

pad_sector_with_zeros:
times ((0x200 - 2) - ($ - $$)) db 0x00

boot_sector_magic_number:
dw 0xAA55

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;[org 0x7E00]   ; 512 bytes after bootloader load address 0x7C00

main:

mov ax, 0x13 ; VGA mode 320x200
int 0x10     ; set VGA mode with BIOS interrupt 0x19
push 0xA000  ; VRAM address : 0xA000:0000
pop es

; write palette: 63 shades of gray and the rest with light blue
; we use 64 colors

mov dx, 0x3C8 ; address register for VGA RGB palette
xor ax,ax
xor bx,bx
out dx, al     ; start at palette color 0
inc dx      ; increment DX to point to data port 0x3C9

grayscale:  ; loop to fill first 63 palette RGB colors with grayscale: (0, 0, 0), (1, 1, 1), ...
out dx, al
out dx, al
out dx, al
inc al
inc bl
cmp bl, 63
jl grayscale

sky:       ; loop to fill colors 64 to 256 with light blue
mov al, 0x66
out dx, al
mov al, 0xb2
out dx, al
mov al, 0xff
out dx, al
inc bl
jnz sky

mov byte [threshold], 16 ; set initial threshold t to 16, store at address 0000:001f

restart:
xor ax, ax
xor bx, bx
xor dx, dx
mov ds, cx

mov di, 63999 ; bottom-right pixel 320*200 - 1
mov si, 0     ; top-left pixel 0

; We process the upper half of the screen left to right and at the same time fill the bottom part right to left.
; Our walls are symmetric with respect to screen center on both x and y axes
frameh: 
mov ax, si     ; current pixel
mov bp, 320    ; 320, number of pixels per row
xor dx, dx
div bp         ; divide ax by bp, quotient x stored in dx, remainder y stored in ax
mov cx, 0x0001 ; set z=1
mov bp, ax     

;process pixels
loop:
mov ax, 100   ; y coordinate of screen center (camera) 
sub ax, bp    ; subtract y coordinate from 100
imul ax, cx   ; compute m = y_dist*z
mov bl, cl    ; save z
shr bl, 2     ; divide z by 4, namely scale z to [0, 63] range
cmp ah, [threshold] ; compare m>>8 (namely ah) to t. We only look at most signficant 8 bits of m
jge display   ; if m>>8 is larger than or equal to t jmp to pixel display
cmp dx, 160   ; cmp x with center x coordinate 160 
jge right_half        ; jmp to right if larger then or equal (the pixel is in the right half of the screen)
mov ax, 160 
sub ax, dx    ; compute x_dist (left half)
jmp mul       ; jump to mul
right_half:
mov ax, dx    
sub ax, 159   ; compute x_dist (right half)
mul:
imul ax, cx   ; compute m = x_dist*y
mov bl, cl    ; save z   
shr bl, 2     ; divide z by 4, namely scale z to [0, 63] range
mov bh, [threshold] 
add bh, 16    
cmp ah, bh    ; compare m>>8 (namely ah) to t+16 (we add 16 to the threshold to make vertical walls look shorter). We only look at most signficant 8 bits of m
jge display   ; if m>>8 is larger than or equal to t jmp to pixel display
inc cl        ; increment z
jnz loop      ; if z is not zero (namely z is not 256) go to loop 
display:
mov byte [es:si], bl ; store pixel color (top-left half)
mov byte [es:di], bl ; store pixel color (bottom-right half)
inc si        ; increment top-left pixel index
dec di        ; decrement bottom-right pixel index
cmp si, 32000 ; compare top-left pixel index with index of first pixel 100th row
jne frameh    ; if not equal, go back to frame loop to process next pixel

;set palette command int 0x10, ah=0x0b. It waits for vertical retrace signal, in modern systems vertical retrace might be too fast so
;we call the interrupt several times with a loop
xor       cx, cx  
mov       cl, 0x1000  ; loop counter
mov       ah, 0x0b 
;vtrace:
int 10h
;loop vtrace

;read keyboard code
in al,60h
; is it up arrow?
cmp al, 48h
je up
; is it down arrow?
cmp al, 50h
je down
jmp restart

up:
mov ah, [threshold] ; increase stored threshold
cmp ah, 96    ; if threshold equal to a maxium value don't increase
je restart    ; jmp to restart to redraw frame
add byte [threshold], 1 ; else increase threshold
jmp restart   ; jmp to restart to redraw frame 
down:         ;
mov ah, [threshold] ; if threshold equal to minimum value don't decrease
cmp ah, 1
je restart    ; jmp to restart to redraw frame
sub byte [threshold], 1 ; else decrease threshold
jmp restart   ; jmp to restart to redraw frame 
threshold: db 0x10;
pad_second_sector_with_zeros:
times ((0x400) - ($ - $$)) db 0x00
