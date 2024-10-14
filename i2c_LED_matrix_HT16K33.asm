;   HT16K33 with LED matrix
;   Example of sending data to LED matrix
;   Richard Turnnidge 2024 

; Key commmands and functions in this code:
;
; configMatrix          Send configuration commands to HT16K33
; clearMatrix           Send all blanks to LED and update display
; sendMatrixData        Send data from local buffer (8 bytes) to the LED and update display
; updateMatrix          Tell LED matrix to update the display with its memory

; clearBuffer           Clear local buffer
; plotPixel             Set a pixel at X,Y (B,C) in local buffer
; unPlotPixel           Clear a pixel at X,Y (B,C) in local buffer
; setBufferData         Takes 8 bytes of data from HL pointer and fills local buffer

; 2x demo routines:     1. Press G - Cycle through 32 8x8 graphic characters
;                       2. Press R - Plot/Unplot random pixels

    .assume adl=1                    ; ez80 ADL memory mode
    .org $40000                      ; load code here
    include "myMacros.inc"

    jp start_here                    ; jump to start of code

    .align 64                        ; MOS header
    .db "MOS",0,1     

    include "delay_routines.asm"
    include "random_routines.asm"

; ------------------
; define configuration constants

i2c_address:        equ $70          ; default $70, can set from $70-$77 with solder pads


; ------------------

start_here:
            
    push af                          ; store all the registers for later when we exit
    push bc
    push de
    push ix
    push iy
        
    CLS

    ld hl, VDUdata
    ld bc, endVDUdata - VDUdata
    rst.lil $18                     ; put simple message on Agon display

    call i2c_open                   ; need to setup i2c port

    call configMatrix               ; configure as inputs or outputs for each pin

    call hidecursor

    call clearMatrix
    call sendMatrixData             ; send default data from memory and update

    jp LOOP_GRAPHICS_CHARS          ; next, start a graphics display loop

; ------------------

EXIT_HERE:

    call clearMatrix
    call i2c_close                  ; close the i2c port
    call hidecursor
    CLS

    pop iy                          ; Pop all registers back from the stack
    pop ix
    pop de
    pop bc
    pop af
    ld hl,0                         ; Load the MOS API return code (0) for no errors.   
    
    ret                             ; Return to MOS

; ------------------
; cycle through 32 8x8 graphics characters on display

LOOP_GRAPHICS_CHARS:
    MOSCALL $1E                     ; get IX pointer to keyvals, currently pressed keys
    ld a, (ix + $0E)    
    bit 0, a                        ; check for ESC key pressed
    jp nz, EXIT_HERE                ; exit if pressed

    ld a, (ix + $06)    
    bit 3, a                        ; check for R key pressed
    jp nz, startRandom              ; start random pixels if pressed

    call pause                      ; so it's not too fast

    ld a, (graphicCounter)          ; get current position through data
    ld de, 0                        ; clear D and E
    ld e, a                         ; put count into E
    ld hl, graphicsData             ; get start of character data
    add hl, de                      ; add the count to HL to get data offset
    push af                         ; store count for later
    call setBufferData              ; transfer data to buffer
    call sendMatrixData             ; send new data to display
    call updateMatrix               ; tell module to refresh
    pop af                          ; get counter back
    add 8                           ; jump 8 places forward in graphic data

    ld (graphicCounter),a           ; store graphic position for next time

    jp LOOP_GRAPHICS_CHARS          ; go round again until keypress  


graphicCounter: .db 0

; ------------------
; Plot and Unplot random dots on display

startRandom:

    call clearBuffer                ; clear our local display buffer
    call sendMatrixData             ; send local buffer to matrix


LOOP_RANDOM_PIXELS:
    MOSCALL $1E                     ; get IX pointer to keyvals, currently pressed keys
    ld a, (ix + $0E)                ; grab byte needed   
    bit 0, a                        ; check for ESC key pressed
    jp nz, EXIT_HERE                ; exit if pressed

    ld a, (ix + $0A)                ; grab byte needed
    bit 3, a                        ; check for G key pressed
    jp nz, LOOP_GRAPHICS_CHARS      ; start graphics characters if pressed

    call get_random_byte            ; randomise start of seed for main random function
    ld (seed), a                    ; set seed

    call get_random_byte_v2         ; A will be 0-255
    and 00000111b                   ; we only want 0-7
    ld b, a                         ; put random 0-7 into B

    call get_random_byte_v2         ; A will be 0-255
    and 00000111b                   ; we only want 0-7
    ld c, a                         ; put random 0-7 into C
    call plotPixel                  ; plot at B,C


    call get_random_byte_v2         ; A will be 0-255
    and 00000111b                   ; we only want 0-7
    ld b, a                         ; put random 0-7 into B
    call get_random_byte_v2         ; A will be 0-255
    and 00000111b                   ; we only want 0-7
    ld c, a                         ; put random 0-7 into C
    call unPlotPixel                ; unplot at B,C

    call sendMatrixData             ; send data from buffer to LED module
    call updateMatrix               ; tell module to refresh

    jp LOOP_RANDOM_PIXELS           ; loop round again until keypress

; ------------------
; send commands 1 at a time to configure matrix

configMatrix:                        

    ld c, i2c_address               ; i2c address (default $70)
    ld b, 1                         ; number of bytes to send
    ld hl, matrixConfigData         ; 'i2c_write_buffer' is where data to be sent is stored

    MOSCALL $21                     ; send byte of data
    inc hl
    MOSCALL $21                     ; send byte of data
    inc hl
    MOSCALL $21                     ; send byte of data
    inc hl
    MOSCALL $21                     ; send byte of data
    inc hl
    MOSCALL $21                     ; send byte of data

    ret 
; ------------------
; commands sent to configure the LED matric

matrixConfigData:

    .db     00100001b               ; S=system off=0 On=1
    .db     10000000b               ; Display: 0=off 1=on no blink
    .db     11100000b               ; 1110DCBA dimming DCBA 0000=dim 1111=bright
    .db     10100000b               ; Row int setup
    .db     10000001b               ; Display: 0=off 1=on no blink

; ------------------
; Send data from local buffer to the LED marix memory
; Does not force a display update

sendMatrixData:                     ; loop through 8 lines of data to send
    ld bc,0                         ; start at 0

_sendLoop:
    push bc                         ; store BC so we don't lose counter
    call sendLine                   ; send 1 line of data
    pop bc                          ; get BC back with counter
    inc b                           ; B is offset into memory
    inc b                           ; inc twice to skip unused odd lines
    inc c                           ; C is offset into our data
    ld a, c                         ; put into A to check if we have done 8 yet
    cp 8                            ; have we done all 8 lines?
    jr nz, _sendLoop                 ; if not finished, go round another go

    ret 

; ------------------
; Send 1 line of data to LED matrix memory
; B is the memory address to fill which will be an even number 0,2,4,...14
; Does not update display

sendLine:
    ld de,0                         ; clear D and E
    ld e, c                         ; get count

    ld hl, localDisplayBuffer       ; start of data
    add hl, de                      ; get start of line we want
    ld a, b                         ; b is memory address
    ld (sendCommand), a             ; set memory destination command
    ld a, (hl)                      ; this is the data
    or a                            ; clear flags
    rlc a                           ; rotate one bit
    call reverseBits                ; reverse the order for the display
    ld (sendByte), a                ; set data to send

    ld c, i2c_address               ; i2c address (default $70)
    ld b, 2                         ; number of bytes to send
    ld hl, sendCommand              ; 'sendCommand' is where 2 byte data to be sent is stored

    MOSCALL $21                     ; send 2 bytes of data

    ret 

sendCommand:                        ; used to send data for each line
    .db 0                           ; this is the matrix memory address command. Will be 0,2,4,6,8...14

sendByte:                          
    .db 0                           ; this is the byte of data to send to matrix memory                      

; ------------------
; takes HL as new data source and puts into default buffer
; used for animating through a file of data

setBufferData:                            
    ld de, localDisplayBuffer       ; destiination
    ld bc, 8                        ; 8 bytes to copy
    ldir                            ; copy the 8 bytes

    ret 

; ------------------

clearBuffer:                        ; takes HL as empty data source and puts into default buffer
    ld de, localDisplayBuffer       ; dest
    ld hl, blank_buffer             ; re-using 16 bytes of blank data from LED command
    ld bc, 8                        ; 16 bytes to copy
    ldir                            ; copy 16 bytes from HL to DE

    ret 

; ------------------

localDisplayBuffer:                 ; 8x8 array for pixels we want to see


    .db     10000000b               ; line 0
    .db     00000000b               ; line 1
    .db     00000000b               ; line 2
    .db     00000000b               ; line 3
    .db     00000000b               ; line 4
    .db     00000000b               ; line 5
    .db     00000000b               ; line 6
    .db     11110000b               ; line 7

blank_buffer:
    .ds 8,0                         ; 8 bytes of 0

; ------------------

plotPixel:                          ; plot x,y (B,C)
    ld de,0
    ld e, c                         ; get line
    ld hl, localDisplayBuffer       ; start of data
    add hl, de                      ; get start of line we want


    ; need to do SET B, A but this command doesn't exist

    ; SET N, A instruction          SET 0, A is: CB C7
    ;                               SET 1, A is: CB CF, etc
    ;                               SET 7, A is: CB FF
    ;                               RESET starts at CB 87, CB 8F, etc
    or a 
    ld a, b                         ; need to x 8 to add to CB C7

    and 00000111b                   ; make sure 7 or less
    ld d, a 
    ld a, 7
    sub d                           ; flip order of bit set
    rlc a
    rlc a
    rlc a                           ; need a x 8

    add $c7                         ; initial number for SET
    ld (bitNum), a 

    ld a, (hl)                      ; get original line

    .db $CB                         ; SET N, A
bitNum:
    .db 0                           ; this creates CB C7, etc to set the bit

    LD (HL), A                      ; store new value
               
    CALL sendMatrixData

    ret

; ------------------

unPlotPixel:                        ; plot x,y (B,C), A=1 to set (on), 0 to reset (off)
    ld de,0
    ld e, c                         ; get line
    ld hl, localDisplayBuffer       ; start of data
    add hl, de                      ; get start of line we want


    ; need to do SET B, A but this command doesn't exist

    ; SET N, A instruction          SET 0, A is: CB C7
    ;                               SET 1, A is: CB CF, etc
    ;                               SET 7, A is: CB FF
    ;                               RESET starts at CB 87, CB 8F, etc
    or a 
    ld a, b                         ; need to x 8 to add to CB C7

    and 00000111b                   ; make sure 7 or less
    ld d, a 
    ld a, 7
    sub d                           ; flip order of bit set
    rlc a
    rlc a
    rlc a                           ; need a x 8

    add $87                         ; initial number for RESET
    ld (bitNum2), a 

    ld a, (hl)                      ; get original line

    .db $CB                         ; SET N, A
bitNum2:
    .db 0                           ; this creates CB 87, etc to set the bit

    LD (HL), A                      ; store new value
               
    CALL sendMatrixData

    ret

; ------------------

clearMatrix:

    ld c, i2c_address               ; i2c address (default $20)
    ld b, 17                        ; number of bytes to send
    ld hl, clearData                ; 'i2c_write_buffer' is where data to be sent is stored

    MOSCALL $21                     ; send 4 byte of data

    call updateMatrix

    ret

clearData:
    .ds 17, $00

; ------------------

updateMatrix:

    ld c, i2c_address               ; i2c address (default $20)
    ld b, 1                         ; number of bytes to send
    ld hl, updateData               ; 'i2c_write_buffer' is where data to be sent is stored

    MOSCALL $21                     ; send 4 byte of data

    ret

updateData:
    .db $81

; ------------------

i2c_open:

    ld c, 3                         ; speed setting
    MOSCALL $1F                     ; open i2c bus
    ret

; ------------------

i2c_close:

    MOSCALL $20                     ; close i2c bus
    ret 

; ------------------
; routine found, destroys L, returns A reversed

reverseBits:                        
    ld l,a    ; a = 76543210
    rlca
    rlca      ; a = 54321076
    xor l
    and 0xAA
    xor l     ; a = 56341270
    ld l,a
    rlca
    rlca
    rlca      ; a = 41270563
    rrc l     ; l = 05634127
    xor l
    and 0x66
    xor l     ; a = 01234567

    ret 

; ------------------
; Pause a while

pause:

    ld a, 00100000b
    call multiPurposeDelay
    ret 

; ------------------
; hide or show screen cursor

hidecursor:
    push af
    ld a, 23
    rst.lil $10
    ld a, 1
    rst.lil $10
    ld a,0
    rst.lil $10                     ; VDU 23,1,0
    pop af
    ret

showcursor:
    push af
    ld a, 23
    rst.lil $10
    ld a, 1
    rst.lil $10
    ld a,1
    rst.lil $10                     ; VDU 23,1,1
    pop af
    ret

; ------------------
; setup simple display

VDUdata:                            
   
    .db 31, 0, 0,  "Agon Light - i2c LED Matrix v06"
    .db 31, 0, 2,  "Press R for Random pixels"
    .db 31, 0, 4,  "Press G for Graphic characters"

    .db 31, 0, 12, "Press ESC to exit"

endVDUdata:

; ------------------
; i2c buffers

i2c_read_buffer:		            ; to store data sent and recieved to i2c
    .ds 32,0                        ; allow 32 bytes even if not needed

i2c_write_buffer:
    .ds 32,0

  
; ------------------
; graphic imports

graphicsData:
    incbin "graphics.bin"           ; a binary file with 32 8x8 graphics

; ------------------
; END
; ------------------
