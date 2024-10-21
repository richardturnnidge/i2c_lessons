;   MCP4725 i2c DAC
;   Richard Turnnidge 2024 


    .assume adl=1                    ; ez80 ADL memory mode
    .org $40000                      ; load code here
    include "myMacros.inc"

    jp start_here                    ; jump to start of code

    .align 64                        ; MOS header
    .db "MOS",0,1     

    include "debug_routines.asm"
    include "delay_routines.asm"

; ------------------
; define configuration constants

i2c_address:        equ $60          ; fixed address


; ------------------

start_here:
            
    push af                          ; store all the registers for later when we exit
    push bc
    push de
    push ix
    push iy
        
    CLS                             ; this is a macro in the macros file

    ld hl, VDUdata
    ld bc, endVDUdata - VDUdata
    rst.lil $18                     ; setup basic display

    call hidecursor                 ; hide the cursor so it doesn't keep flickering

    call i2c_open                   ; need to setup i2c port

reset:
    ld d, 0                         ; D is a counter for the analog value

LOOP_HERE:
    MOSCALL $1E                     ; get IX pointer to keyvals, currently pressed keys
    ld a, (ix + $0E)    
    bit 0, a                        ; check for ESC key pressed
    jp nz, EXIT_HERE                ; exit if pressed

    inc d 

    call set_analog_value           ; set output pin voltage
    call short_pause                ; pause 

    ld a, d
    cp 255                          ; if we got to 255 then wait
    jr z, WAIT_HERE

    jp LOOP_HERE                      

WAIT_HERE:
    MOSCALL $1E                     ; get IX pointer to keyvals, currently pressed keys
    ld a, (ix + $09)    
    bit 1, a                        ; check for ENTER key pressed
    jp nz, reset                    ; reset count and loop again if pressed

    ld a, (ix + $0E)    
    bit 0, a                        ; check for ESC key pressed
    jp nz, EXIT_HERE                ; exit if pressed

    jp WAIT_HERE                      

; ------------------

set_analog_value:                   ; arrive with analog level in D (0-255)
                                    ; although 12 bit resolution, we only use top 8 bits in this example
    ld a, 01000000b  
    ld (i2c_write_buffer), a        ; here we send a command to write to DAC register
    ld a, d  
    ld (i2c_write_buffer + 1), a    ; then send the MSB of the voltage (d)
    ld a, 255;0  
    ld (i2c_write_buffer + 2), a    ; followed by the LSB (only upper nibble is used), which in this demo is 0

    ld c, i2c_address               ; i2c address (default $10)
    ld b, 3                         ; number of bytes to send
    ld hl, i2c_write_buffer         ; 'i2c_write_buffer' is where data to be sent is stored
    MOSCALL $21                     ; send 3 bytes of data  

    ld b, 0                         ; x pos = 0
    ld c, 4                         ; y pos = 4
    ld a, d                         ; A is now analog level used
    call debugA                     ; print the value of A (D) to screen in Hex

    ret 


; ------------------

short_pause:
    ld a, 00001000b               
    call multiPurposeDelay          ; very short pause
    ret

; ------------------

EXIT_HERE:

    ld d,0

    call send_voltage               ; set pin values

    call i2c_close		            ; close the i2c port
    call showcursor                 ; get the cursor back
    CLS

    pop iy                          ; Pop all registers back from the stack
    pop ix
    pop de
    pop bc
    pop af
    ld hl,0                         ; Load the MOS API return code (0) for no errors.   
    
    ret                             ; Return to MOS

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


hidecursor:                         ; VDU 23,1,0
    push af
    ld a, 23
    rst.lil $10
    ld a, 1
    rst.lil $10
    ld a,0
    rst.lil $10                 
    pop af
    ret


showcursor:                         ; VDU 23,1,0
    push af
    ld a, 23
    rst.lil $10
    ld a, 1
    rst.lil $10
    ld a,1
    rst.lil $10             
    pop af
    ret

 ; ------------------

VDUdata:                            ; setup simple display
   
    .db 31, 0, 0, "Agon Light - MCP4725 DAC"
    .db 31, 0, 2, "MSB   LSB ($00)"
    .db 31, 0, 8, "Press and hold ESC to exit"
    .db 31, 0, 10, "Or ENTER to restart"

endVDUdata:

; ------------------

i2c_read_buffer:		            ; to store data sent and recieved to i2c

    .ds 32,$FF                        ; allow 32 bytes even if not needed

i2c_write_buffer:
        .ds 32,0

  