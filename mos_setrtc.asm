; 
; Title:        mos_setrtc
; Author:       Richard Turnnidge 2024
; A MOSlet to set the time of Agon's internal RTC from an battery backed up DS3231 RTC module
;
; Usage:
;         *mos_setrtc
;

    macro MOSCALL arg1
        ld a, arg1
        rst.lil $08
    endmacro


    .assume adl=1   ; We start up in full 24bit mode, allowing full memory access and 24-bit wide registers
    .org $0B0000    ; This program assembles to MOSlet RAM area org $0B0000


    jp start        ; skip headers

; Quark MOS header 
    .align 64       ; Quark MOS expects programs that it LOADs,to have a specific signature
                    ; Starting from decimal 64 onwards
    .db "MOS"       ; MOS header 'magic' characters
    .db 00h         ; MOS header version 0 - the only in existence currently afaik
    .db 01h         ; Flag for run mode (0: Z80, 1: ADL) - We start up in ADL mode here

_exec_name:         .DB  "mos_setrtc.bin", 0      ; The executable name, only used in argv

; ---------------------------------------------
;
;   INITIAL SETUP CODE HERE
;
; ---------------------------------------------

start:                      
    push af                     ; Push all registers to the stack
    push bc
    push de
    push ix
    push iy
    ld a, mb                    ; grab current MB to restore when exiting
    push af 
    xor a 
    ld mb, a                    ; put 0 into MB


    ; main code starts here

    call open_i2c


    ld c, $68                   ; i2c address ($68 for DS3231 RTC module)
    ld b,1                      ; number of bytes to send
    ld hl, i2c_write_buffer
    ld (hl), $00
    MOSCALL $21                 ; write 0 to I2C

    cp 1                        ; 1 in A returned means no response from i2c slave 
    jp z,no_rtc

    ld a, 00000100b
    call multiPurposeDelay

    call readi2ctime            ; get all the data and set it
    call setAgonTime            ; set the internal sys vars

    jp now_exit


no_rtc:
    ld hl, errMSG
    call PRSTR

now_exit:                   ; Close i2c, cleanup stack, prepare for return to MOS
    call close_i2c
                            
    pop af 
    ld mb, a                ; restore MB
    pop iy                  ; Pop all registers back from the stack
    pop ix
    pop de
    pop bc
    pop af
    ld hl,0                 ; Load the MOS API return code (0) for no errors.
    ret                     ; Return to MOS


; ---------------------------------------------

readi2ctime:                        ; read data from i2c rtc module

    ld c, $68                       ; i2c address ($68)
    ld b,1                          ; number of bytes to send
    ld hl, i2c_write_buffer
    ld (hl), $00                    ; set fisrt byte to send a 00
    MOSCALL $21
   
    ld a, 00000100b
    call multiPurposeDelay
    
    ld c, $68
    ld b, 7
    ld hl, i2c_read_buffer
    MOSCALL $22                     ; ask for 7 bytes of data from first memory position

    ld a, 00000010b
    call multiPurposeDelay
    
    ld hl, i2c_read_buffer
    ld a, (hl)
    call bcd2bin                    ; i2c data arrives in BCD format, but we want in binary
    ld (SECONDS), a
    inc hl

    ld a, (hl)
    call bcd2bin                    ; i2c data arrives in BCD format, but we want in binary
    ld (MINUTES), a
    inc hl

    ld a, (hl)
    call bcd2bin                    ; i2c data arrives in BCD format, but we want in binary
    ld (HOURS), a
    ld b, 24 
    inc hl

    ld a, (hl)
    call bcd2bin                    ; i2c data arrives in BCD format, but we want in binary
    ld (DAY), a                     ; note: this is not needed to set Agon's clock
    inc hl

    ld a, (hl)
    call bcd2bin                    ; i2c data arrives in BCD format, but we want in binary
    ld (DATE), a
    inc hl

    ld a, (hl)
    call bcd2bin                    ; i2c data arrives in BCD format, but we want in binary
    ld (MONTH), a
    inc hl

    ld a, (hl)
    call bcd2bin                    ; i2c data arrives in BCD format, but we want in binary
    add 20                          ; date starts from 1980, so add 20 to get the correct 2000+ year
    ld (YEAR), a
    inc hl

    ret 

; ---------------------------------------------

setAgonTime:                        ; set internal RTC

    ld hl, LFCR
    call PRSTR                      ; print a linefeed

    ld hl, rtc_data                 ; set with 6 bytes stored at rtc_data
    MOSCALL $13                     ; mos_setrtc

    ld hl, timeSetMSG
    call PRSTR                      ; print a message

    ld hl, agonrtcdata
    MOSCALL $12                     ; mos_getrtc. Agon's RTC arrives as a text string at agonrtcdata
    call PRSTR                      ; print the Agon's clock string

    ld hl, LFCR
    call PRSTR                      ; print a linefeed

    ret 

; ---------------------------------------------

open_i2c:

    ld c, 3                         ; making assumption based on Jeroen's code
    MOSCALL $1F                     ; open i2c               
   
   ret

; ---------------------------------------------

close_i2c:

    MOSCALL $20                     ; close i2c

    ret 

; ---------------------------------------------

PRSTR:                              ; Print a zero-terminated string
    LD A,(HL)
    OR A
    RET Z
    RST.LIL 10h
    INC HL
    JR PRSTR

; ---------------------------------------------
;
;   DATA
;
; ---------------------------------------------

errMSG:             .db "No DS3231 RTC module found on address $68.\r\n",0
timeSetMSG:         .db "Agon's time set to: ",0
LFCR:               .db "\r\n",0

;   store RTC values. send data in this order to set internal RTC
rtc_data:  

YEAR:           .db     0
MONTH:          .db     0
DATE:           .db     0

HOURS:          .db     0 
MINUTES:        .db     0 
SECONDS:        .db     0  

DAY:            .db     0   ; not used on Agon clock


agonrtcdata:                ; buffer fro Agon's RTC when requested
    .ds 32,0

i2c_read_buffer:            ; i2c buffer space for reading
    .ds 32,0

i2c_write_buffer:           ; i2c buffer space for writing
    .ds 32,0


; ---------------------------------------------
;   a(BCD) => a(BIN) 
;   Converts BCD hex to binary
; ---------------------------------------------

bcd2bin:
    push bc
    ld c,a
    and $f0
    srl a
    ld  b,a
    srl a
    srl a
    add a,b
    ld b,a
    ld a,c
    and $0f
    add a,b
    pop bc
    ret

; ---------------------------------------------
;
;   DELAY ROUTINES
;
; ---------------------------------------------

; routine waits a fixed time, then returns

multiPurposeDelay:                      
    push bc 

                            ; arrive with A =  the delay byte. One bit to be set only.
    ld b, a 
    MOSCALL $08             ; get IX pointer to sysvars

waitLoop:

    ld a, (ix + 0)          ; ix+0h is lowest byte of clock timer

                ; need to check if bit set is same as last time we checked.
                ;   bit 0 - changes 128 times per second
                ;   bit 1 - changes 64 times per second
                ;   bit 2 - changes 32 times per second
                ;   bit 3 - changes 16 times per second

                ;   bit 4 - changes 8 times per second
                ;   bit 5 - changes 4 times per second
                ;   bit 6 - changes 2 times per second
                ;   bit 7 - changes 1 times per second
                ; eg. and 00000010b           ; check 1 bit only
    and b 
    ld c,a 
    ld a, (oldTimeStamp)
    cp c                    ; is A same as last value?
    jr z, waitLoop      ; loop here if it is
    ld a, c 
    ld (oldTimeStamp), a    ; set new value

    pop bc
    ret

oldTimeStamp:   .db 00h

; ---------------------------------------------
;
;  END
;
; ---------------------------------------------





