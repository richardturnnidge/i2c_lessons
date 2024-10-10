;   PCF8575 16 bit i/o expander port
;   Example of output on pins to light LED
;   Richard Turnnidge 2024 


    .assume adl=1                    ; ez80 ADL memory mode
    .org $40000                      ; load code here
    include "myMacros.inc"

    jp start_here                    ; jump to start of code

    .align 64                        ; MOS header
    .db "MOS",0,1     

    include "debug_routines.asm"

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

    call hidecursor

LOOP_HERE:
    MOSCALL $1E                     ; get IX pointer to keyvals, currently pressed keys
    ld a, (ix + $0E)    
    bit 0, a                        ; check for ESC key pressed
    jp nz, EXIT_HERE                ; exit if pressed

    call checkInputs                ; set pin values

    jp LOOP_HERE		              

; ------------------

configPins:                         ; In this example, we set all pins P0-P7 as outputs
                                    ; and all pins P10-P17 as inputs.
                                    ; But, any combination over the 16 bits can be used

    ld c, i2c_address               ; i2c address (default $20)
    ld b, 2                         ; number of bytes to send
    ld hl, i2c_write_buffer         ; 'i2c_write_buffer' is where data to be sent is stored
    ld (hl), 11111111b              ; sending $FF initially sets all pins as outputs
    inc hl
    ld (hl), 00000000b              ; sending $0 initially sets all pins as inputs
    dec hl                          ; set HL back to 'i2c_write_buffer'
    MOSCALL $21                     ; send 2 byte of data

    ret 
; ------------------

checkInputs:

    ld c, i2c_address               ; i2c address (default $20)
    ld b, 2                         ; number of bytes to send
    ld hl, i2c_read_buffer          ; 'i2c_write_buffer' is where data to be sent is stored
    MOSCALL $22                     ; get two byts of data
                                    ; byte 1 is outputs
                                    ; byte 2 is inputs in this example

    ld a, (i2c_read_buffer)
    ld b, 0
    ld c, 8 
    ld d, 8
    call printBin                   ; debug P0-P7

    ld a, (i2c_read_buffer + 1)
    ld b, 10
    ld c, 8 
    ld d, 8
    call printBin                   ; debug P10-P17


    ld a, (i2c_read_buffer + 1)     ; grab value of P10-P17
    cpl                             ; invert the input so LED is on when button pressed

    ld (i2c_write_buffer),a         ; set value of P0-P7 to send

    ld a, 0
    ld (i2c_write_buffer + 1),a     ; set value of P10-P17 to send (all 0 = set as inputs)


    ld c, i2c_address               ; i2c address (default $20)
    ld hl, i2c_write_buffer         ; 'i2c_write_buffer' is where data to be sent is stored
    ld b, 2
    MOSCALL $21                     ; send 2 byte of data
    ret

; ------------------

EXIT_HERE:

    call i2c_close		            ; close the i2c port
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

i2c_open:

    ld c, 3                         ; speed setting
    MOSCALL $1F                     ; open i2c bus
    ret

; ------------------

i2c_close:

    MOSCALL $20                     ; close i2c bus
    ret 


; ------------------

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

VDUdata:                            ; setup simple display
   
    .db 31, 0, 0, "Agon Light - i2c I/O Expander PCF8575"
    .db 31, 0, 2, "Press button to light LED"
    .db 31, 0, 4, "Outputs:  Inputs:"
    .db 31, 0, 6, "P0-P7     P10-P17"
    .db 31, 0, 12, "Press ESC to exit"

endVDUdata:

; ------------------

i2c_read_buffer:		            ; to store data sent and recieved to i2c
    .ds 32,0                        ; allow 32 bytes even if not needed

i2c_write_buffer:
    .ds 32,0

  