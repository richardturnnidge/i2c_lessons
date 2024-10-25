;   I2C Real Time Clock DS3231
;   Same as used on MOD-RTC2  
;
;   Simple Clock reading data from RTC module
;   Thanks to Tim Gilmore for all the testing and inspiration.
  

    .assume adl=1                   ; ez80 ADL memory mode
    .org $40000                     ; load code here
    include "myMacros.inc"

    jp start_here                   ; jump to start of code

    .align 64                       ; MOS header
    .db "MOS",0,1     

    include "debug_routines.asm"
    include "delay_routines.asm" 

i2c_address:        equ $68         ; this is the default for the RTC


start_here:
            
    push af                         ; store all the registers
    push bc
    push de
    push ix
    push iy

; ------------------
; This is our actual code in ez80 assembly

    CLS

    ld hl, VDUdata                  ; print basic text to screen
    ld bc, endVDUdata - VDUdata
    rst.lil $18
  
    call hidecursor                 ; hide the cursor

    call open_i2c                   ; open i2c port

LOOP_HERE:

    MOSCALL $1E                     ; get IX pointer to keyvals, currently pressed keys
    ld a, (ix + $0E)    
    bit 0, a    
    jp nz, EXIT_HERE                ; ESC key to exit


    ld a, 00000100b		            
    call multiPurposeDelay          ; wait a bit as we don't need it too fast
    
   
    call update_clock               ; read latest time data and print to screen

    jr LOOP_HERE                    ; keep looping until ESC pressed
    

; ------------------

EXIT_HERE:

                        
    call close_i2c                  ; close i2c port

    CLS			                    ; Clear the screen when exiting
    call showcursor                 ; show the cursor

    pop iy                          ; Pop all registers back from the stack
    pop ix
    pop de
    pop bc
    pop af
    ld hl,0                         ; Load the MOS API return code (0) for no errors.   
    
    ret                             ; Return to MOS


; ------------------

open_i2c:

    ld c, 3                         ; speed value, default fast 3 is normally OK
    MOSCALL $1F                     ; open i2c     			 
   
    ret 

; ------------------

update_clock:

; first tell the module we want to read some data, and where from ($00)

    ld c, i2c_address   		    ; i2c address ($68)
    ld b,1			                ; number of bytes to send
    ld hl, i2c_write_buffer         ; buffer to send from
    ld (hl), $00                    ; write first memory register $00 as command
    MOSCALL $21                     ; write data
   
    ld a, 00000100b
    call multiPurposeDelay          ; wait a bit
    
; then read the number of bytes from the module's memory

    ld c, i2c_address               ; i2c address ($68)
    ld b, 7                         ; number of bytes to read
    ld hl, i2c_read_buffer          ; buffer to put data into
    MOSCALL $22                     ; read data

    ld a, 00000010b
    call multiPurposeDelay          ; wait a bit

    
; put the data into our variables

    ld hl, i2c_read_buffer          ; get pointer to buffer of data

    ld a, (hl)                      ; 1st byte is the seconds
    ld (SECONDS), a
    inc hl

    ld a, (hl)                      ; 2nd byte is the minutes
    ld (MINUTES), a
    inc hl

    ld a, (hl)                      ; 3rd byte is the hours
    ld (HOURS), a
    inc hl

    ld a, (hl)                      ; 4th byte is the day of the week
    ld (DAY), a
    inc hl

    ld a, (hl)                      ; 5th byte is the day date
    ld (DATE), a
    inc hl

    ld a, (hl)                      ; 6th byte is the month of the year
    ld (MONTH), a
    inc hl

    ld a, (hl)                      ; 7th byte is the year (- 2000). eg. 2024 will be 24
    ld (YEAR), a


; print values from variables to the screen at given locations
; NOTE: values returned are in BCD format
; so printing a hex value will work here

    ld b, 6
    ld c, 1
    ld a, (SECONDS)
    call debugA                     ; display seconds

    ld b, 3
    ld c, 1
    ld a, (MINUTES)
    call debugA                     ; display minutes

    ld b, 0
    ld c, 1
    ld a, (HOURS)
    call debugA                     ; display hours


    ld b, 10
    ld c, 1
    ld a, (DAY)
    call debugA                     ; display day
   
    ld b, 14
    ld c, 1
    ld a, (DATE)
    call debugA                     ; display date

    ld b, 17
    ld c, 1
    ld a, (MONTH)
    call debugA                     ; display month

    ld b, 22
    ld c, 1
    ld a, (YEAR)
    call debugA                     ; display year
    
    ret 

 ; ------------------

close_i2c:

    MOSCALL $20                     ; close i2c

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

VDUdata:

    .db 31, 0,10, "CLOCK - Date is in UK format"
    .db 31, 0,12, "Press Esc to exit"
    .db 31, 2,1, ":"
    .db 31, 5,1, ":"
    .db 31, 16,1, "/"
    .db 31, 19,1, "/20"
endVDUdata:

; ------------------


i2c_read_buffer:		          ; buffers for i2c data
    .ds 32,0

i2c_write_buffer:
    .ds 32,0

; ------------------


SECONDS:  	.db     0	          ; store RTC values
MINUTES:    .db     0
HOURS:		.db	    0
HOURSMODE:	.db	    0
DAY:		.db	    0
DATE:		.db  	0
MONTH:		.db 	0
YEAR:		.db  	0


; ------------------



