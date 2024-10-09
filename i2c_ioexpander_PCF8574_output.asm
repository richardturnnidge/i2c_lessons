;   PCF8574 8 bit i/o expander port
;   Example of output on pins to light LED
;   Richard Turnnidge 2024 


    .assume adl=1                    ; ez80 ADL memory mode
    .org $40000                      ; load code here
    include "myMacros.inc"

    jp start_here                    ; jump to start of code

    .align 64                        ; MOS header
    .db "MOS",0,1     

    include "delay_routines.asm"

; ------------------
; define configuration constants

i2c_address:        equ $20          ; from $20 to $27 set with A0-A2 inputs


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

    call configPins                 ; configure as inputs or outputs for each pin

    call all_pins_on

LOOP_HERE:
    MOSCALL $1E                     ; get IX pointer to keyvals, currently pressed keys
    ld a, (ix + $0E)    
    bit 0, a                        ; check for ESC key pressed
    jp nz, EXIT_HERE                ; exit if pressed

    call moveLED                    ; set pin values
             
    call short_pause                ; pause 

    jp LOOP_HERE		              

 ; ------------------

EXIT_HERE:

    call all_pins_off
    call i2c_close		            ; close the i2c port

    CLS

    pop iy                          ; Pop all registers back from the stack
    pop ix
    pop de
    pop bc
    pop af
    ld hl,0                         ; Load the MOS API return code (0) for no errors.   
    
    ret                             ; Return to MOS

; ------------------

short_pause:
    ld a, 00100000b               
    call multiPurposeDelay          ; pause approx 1/2 seconds
    ret

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

configPins:

    ld c, i2c_address               ; i2c address (default $20)
    ld b, 1                         ; number of bytes to send
    ld hl, i2c_write_buffer         ; 'i2c_write_buffer' is where data to be sent is stored
    ld (hl), 11111111b              ; sending $FF initially sets all pins as outputs
    MOSCALL $21                     ; send 1 byte of data

    ret 

; ------------------

moveLED:
                          
    ld a, (bitNum)                  ; get currect bit value
    rrc a                           ; 8-bit rotation to right, the bit leaving on the right copied to bit 7.
    ld (bitNum), a                  ; store it for next time

    ld c, i2c_address               ; i2c address (default $20)
    ld b, 1                         ; number of bytes to send
    ld hl, i2c_write_buffer         ; 'i2c_write_buffer' is where data to be sent is stored
    ld (hl), a                      ; send the current pin bit values
    MOSCALL $21                     ; send 1 byte of data

    ret 

bitNum:     .db 11111110b           ; we will shift this bit on each cycle

 ; ------------------

all_pins_off:
                                   
    ld c, i2c_address               ; i2c address (default $20)
    ld b, 1                         ; number of bytes to send
    ld hl, i2c_write_buffer         ; 'i2c_write_buffer' is where data to be sent is stored
    ld (hl), 11111111b              ; sending $FF sets all pins high = LED goes OFF
    MOSCALL $21                     ; send 1 byte of data

    ret 

; ------------------

all_pins_on:
                                    
    ld c, i2c_address               ; i2c address (default $20)
    ld b, 1                         ; number of bytes to send
    ld hl, i2c_write_buffer         ; 'i2c_write_buffer' is where data to be sent is stored
    ld (hl), 00000000b              ; sending $00 sets all pins low = LED goes ON
    MOSCALL $21                     ; send 1 byte of data
 
    ret 

; ------------------

VDUdata:                            ; setup simple display
   
    .db 31, 0, 0, "Agon Light - i2c I/O Expander PCF8574"
    .db 31, 0, 2, "LOW pins sink voltage, so LED is ON"
    .db 31, 0, 8, "Press and hold ESC to exit"

endVDUdata:

; ------------------

i2c_read_buffer:		            ; to store data sent and recieved to i2c
    .ds 32,0                        ; allow 32 bytes even if not needed

i2c_write_buffer:
    .ds 32,0

  