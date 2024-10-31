;   Richard Turnnidge 2024
;   Nunchuck demo using Nunchuck library

    .assume adl=1                       ; ez80 ADL memory mode
    .org $40000                         ; load code here
    include "myMacros.inc"
    jp start_here                       ; jump to start of code

    .align 64                           ; MOS header
    .db "MOS",0,1     

    include "debug_routines.asm"
    include "delay_routines.asm"
    include "nunchuck.inc"

start_here:
            
    push af                             ; store all the registers
    push bc
    push de
    push ix
    push iy

; ------------------
    call hidecursor                     ; hide the cursor

    CLS


    call i2c_open

    call nunchuck_exists                ; returns error code in A. 0 is good news
    cp 0 
    jp nz, EXIT_ERROR

    call nunchuck_open                  ; need to setup i2c port


    ld hl, string                       ; address of string to use
    ld bc, endString - string           ; length of string, or 0 if a delimiter is used
    rst.lil $18                         ; Call the MOS API to send data to VDP 

LOOP_HERE:
    MOSCALL $1E                         ; get IX pointer to keyvals, currently pressed keys
    ld a, (ix + $0E)    
    bit 0, a    
    jp nz, EXIT_HERE                    ; ESC key to exit

    call nunchuck_update                ; update the data from the nunchuck
    call displayNunchuckData            ; display latest data

    ld a, 00001000b
    call multiPurposeDelay              ; wait a bit

    jr LOOP_HERE


; ------------------

EXIT_ERROR:                             ; exit here if no nunchuck found
    ld hl, err_string
    call printString
    jr exit2

EXIT_HERE:                              ; exit here under user control
    CLS 

exit2:

    call i2c_close                      ; need to close i2c port
    call showcursor


    pop iy                              ; Pop all registers back from the stack
    pop ix
    pop de
    pop bc
    pop af
    ld hl,0                             ; Load the MOS API return code (0) for no errors.   

    ret                                 ; Return to MOS

; ------------------

displayNunchuckData:

    ld b, 0                             ; print at B, C hex data in A
    ld c, 2
    ld a,(nunchuck_joyX)
    call debugA

    ld b, 0
    ld c, 3
    ld a,(nunchuck_joyY)
    call debugA

    ld b, 0
    ld c, 5
    ld a,(nunchuck_angleX)
    call debugA

    ld b, 0
    ld c, 6
    ld a,(nunchuck_angleY)
    call debugA

    ld b, 0
    ld c, 7
    ld a,(nunchuck_velocityZ)
    call debugA

    ld b, 0
    ld c, 9
    ld a,(nunchuck_btnC)
    call debugA

    ld b, 0
    ld c, 10
    ld a,(nunchuck_btnZ)
    call debugA

    ld b, 4                             ; print at B, C binary data in A
    ld c, 13
    ld a,(nunchuck_joyD)
    ld d, 8
    call printBin

    ret 

 ; ------------------

hidecursor:
    push af
    ld a, 23
    rst.lil $10
    ld a, 1
    rst.lil $10
    ld a,0
    rst.lil $10                         ; VDU 23,1,0
    pop af
    ret


showcursor:
    push af
    ld a, 23
    rst.lil $10
    ld a, 1
    rst.lil $10
    ld a,1
    rst.lil $10                         ; VDU 23,1,1
    pop af
    ret

 ; ------------------

string:

    .db 31, 0,0,"i2c Nunchuck Lesson"
    .db 31, 4,2,"nunchuck_joyX"
    .db 31, 4,3,"nunchuck_joyY"
    .db 31, 4,5,"nunchuck_angleX"
    .db 31, 4,6,"nunchuck_angleY"
    .db 31, 4,7,"nunchuck_velocity Z"
    .db 31, 4,9,"nunchuck_btnC"
    .db 31, 4,10,"nunchuck_btnZ"
    .db 31, 4,12,"nunchuck_joyD"

endString:

err_string:
    .db "Error - no Nunchuck",10,13,0

; -----------------






























