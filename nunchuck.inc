; Nunchuck i2c library
; Richard Turnnidge 2024. v 0.02
; 
; call 'nunchuck_exists' to check for nunchuck
; call 'i2c_open'        to open i2c port
; call 'nunchuck_open'   to configure nunchuck
; call 'nunchuck_update' to retrieve fresh data
; call 'i2c_close'       to close the i2c connection
;
; Available byte info:
; 
; nunchuck_btnC:       0 off, 1 pressed
; nunchuck_btnZ:       0 off, 1 pressed

; nunchuck_joyX:       0 - 255. 128 is centre
; nunchuck_joyY:       0 - 255. 128 is centre
; nunchuck_joyD:       Digital binary of joystick directions, as per Console8 xxxx0000b

; nunchuck_angleX:     0 - 255. 128 is centre
; nunchuck_angleY:     0 - 255. 128 is centre
; nunchuck_velocityZ:  0 - 255. 128 is centre. NOTE above may not get full range of 0 - 255
;


; ---------------------------------------------------------------------------
;
;   OPEN I2C PORT
;
; ---------------------------------------------------------------------------

i2c_open:

    ld c, 3                             ; fast speed
    MOSCALL $1F                         ; open i2c
    ret

; ---------------------------------------------------------------------------
;
; 	CHECK IF NUNCHUCK IS CONNECTED
;
; ---------------------------------------------------------------------------
; will return report code in A, 0 if all ok

nunchuck_exists:

    ld c, nunchuck_addr                 ; i2c address
    ld b, 1                             ; number of bytes to send
    ld hl, nunchuck_write_buffer

    ld (hl), $00

    ld hl, nunchuck_write_buffer
    MOSCALL $21


    ret

; ---------------------------------------------------------------------------
;
;   OPEN NUNCHUCK I2C CONNECTION
;
; ---------------------------------------------------------------------------

nunchuck_open:

    ld c, nunchuck_addr  		         ; i2c address
    ld b, 2                     	     ; number of bytes to send
    ld hl, nunchuck_write_buffer

    ld (hl), $F0
    inc hl 
    ld (hl), $55
    ld hl, nunchuck_write_buffer
    MOSCALL $21

    ld c, nunchuck_addr                   ; i2c address
    ld b, 2                     	      ; number of bytes to send
    ld hl, nunchuck_write_buffer

    ld (hl), $FB
    inc hl 
    ld (hl), $00
    ld hl, nunchuck_write_buffer
    MOSCALL $21


    ld c, nunchuck_addr                    ; i2c address
    ld b, 1                     	       ; number of bytes to send
    ld hl, nunchuck_write_buffer     	   ; send a $00 to restet i2c data position

    ld (hl), $00			

    MOSCALL $21				               ; reset memory read address to $00

    ret 

; ---------------------------------------------------------------------------
;
; 	UPDATE NUNCHUCK POSITION / BUTTON DATA
;
; ---------------------------------------------------------------------------

nunchuck_update:

    ld c, nunchuck_addr                     ; i2c address
    ld b, 1                     	        ; number of bytes to send
    ld hl, nunchuck_write_buffer     	    ; send a $00 to restet i2c data position
    ld (hl), $00
    MOSCALL $21				                ; reset memory read address to $00


    ld c, nunchuck_addr
    ld b,6                    		        ; number of bytes to read
    ld hl, nunchuck_read_buffer
    MOSCALL $22


    ld iy, nunchuck_read_buffer		        ; contains 6 bytes of data

    ld a, (iy + 0)
    ld (nunchuck_joyX), a

    ld a, (iy + 1)
    ld (nunchuck_joyY), a

    ld a, (iy + 2)
    sub 64
    sla a
    ld (nunchuck_angleX), a

    ld a, (iy + 3)
    sub 64
    sla a
    ld (nunchuck_angleY), a

    ld a, (iy + 4)
    ld (nunchuck_velocityZ), a

    ld a, (iy + 5)


    and 00000001b
    ld (nunchuck_btnC), a

    ld a, (iy + 5)

    sra a

    and 00000001b
    ld (nunchuck_btnZ), a



    ; create Digital version of joystick
    ; bits for Console8 compatability

    ld d, 255                       ; reset before we start. Tied high, so a direction will set to 0
    
    ld a, (nunchuck_joyX)
    cp 110
    jr nc, j1                       ; if less than 110 then assume LEFT
    res 5,d 
j1:
    ld a, (nunchuck_joyX)
    cp 140
    jr c, j2                        ; if bigger than 140 then assume RIGHT
    res 7,d 
j2:
    ld a, (nunchuck_joyY)
    cp 110
    jr nc, j3                       ; if less than 110 then assume DOWN
    res 3,d 
j3:
    ld a, (nunchuck_joyY)
    cp 140
    jr c, j4                        ; if bigger than 140 then assume UP
    res 1,d 
j4:

    ld a, d 
    ld (nunchuck_joyD), a

    ret 

; ---------------------------------------------------------------------------
;
; 	CLOSE NUNCHUCK I2C CONNECTION
;
; ---------------------------------------------------------------------------

i2c_close:

     MOSCALL $20

    ret 

; ---------------------------------------------------------------------------
;
; 	NUNCHUCK DATA
;
; ---------------------------------------------------------------------------

nunchuck_addr: 	equ $52     ; i2c bus address

nunchuck_read_buffer:
	.ds 20,0

nunchuck_write_buffer:
	.ds 6,0

nunchuck_btnC:       .db     0
nunchuck_btnZ:       .db     0

nunchuck_joyX:       .db     0
nunchuck_joyY:       .db     0

nunchuck_joyD:       .db     0

nunchuck_angleX:     .db     0
nunchuck_angleY:     .db     0
nunchuck_velocityZ:  .db     0













