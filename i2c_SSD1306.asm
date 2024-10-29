;   SSD1306 OLED DISPLAY 128x64 monochrome pixels
;   Richard Turnnidge 2024 

    .assume adl=1                    ; ez80 ADL memory mode
    .org $40000                      ; load code here
    include "myMacros.inc"

    jp start_here                    ; jump to start of code

    .align 64                        ; MOS header
    .db "MOS",0,1     

    include "delay_routines.asm"
; ------------------------------------
; define configuration constants

i2c_address:            equ $3C          

COMMAND_REG:            equ $80 
DATA_REG:               equ $40 
NORMAL:                 equ $A6
INVERT:                 equ $A7

packman_row:            equ 7

;   Useful oLed routines used in this program:
;
;       oLed_initDisplay        prepares oLed display
;       oLed_clearDisplay       clears oLed screen
;       oLed_setOledCursorPos   B is X column, C is Y row
;       oLed_printChar          A is char to print
;       oLed_printCharString    HL is pointer to 0 terminated string
;       oLed_invert             Set display to inverse mode
;       oLed_normal             Set display to normal mode
;       oLed_sendCommand        command is in A
;       oLed_sendData           command is in A

; ------------------------------------
;
;   START OF MAIN PROGRAM
;
; ------------------------------------

start_here:
            
    push af                          ; store all the registers for later when we exit
    push bc
    push de
    push ix
    push iy
        
    CLS                             ; this macro is in our "myMacros.inc" file

    ld hl, VDUdata
    ld bc, endVDUdata - VDUdata
    rst.lil $18                     ; print simple message on Agon display

    call i2c_open                   ; need to setup i2c port

    call oLed_initDisplay           ; send config to oLed

    ld a, 00010000b
    call multiPurposeDelay          ; give display time to sort itself out

    call oLed_clearDisplay          ; clear oLed screen before srawing text, etc

; All ready, now print some things to the oLed screen...

; Print line of text in middle of row 2

    ld b, 12                        ; B = x column (0-127)
    ld c, 2                         ; C = y row (0-7)
    call oLed_setOledCursorPos      ; set cursor position on oLed

    ld hl, msgStr1                  ; point HL to message to print
    call oLed_printCharString       ; pring a 0 terminate string

; Print line of text in middle of row 5

    ld b, 3                         ; B = x column (0-127)
    ld c, 5                         ; C = y row (0-7)
    call oLed_setOledCursorPos      ; set cursor position on oLed

    ld hl, msgStr2                  ; point HL to message to print
    call oLed_printCharString       ; pring a 0 terminate string

; Print a UDG 'box' in top left

    ld b, 0                         ; B = x column (0-127)
    ld c, 0                         ; C = y row (0-7)
    call oLed_setOledCursorPos      ; set cursor position on oLed
    ld a, 127
    call oLed_printChar             ; print UDG 127

; Print a UDG 'box' in bottom right

    ld b, 122                       ; B = x column (0-127)
    ld c, 0                         ; C = y row (0-7)
    call oLed_setOledCursorPos      ; set cursor position on oLed
    ld a, 127
    call oLed_printChar             ; print UDG 127


    ld b, 0                         ; B will be position counter

; Print a UDG 'man 1' in top row

    ld b, 40                        ; B = x column (0-127)
    ld c, 0                         ; C = y row (0-7)
    call oLed_setOledCursorPos      ; set cursor position on oLed
    ld a, 128
    call oLed_printChar             ; print UDG 127

; Print a UDG 'man 2' in top row

    ld b, 80                        ; B = x column (0-127)
    ld c, 0                         ; C = y row (0-7)
    call oLed_setOledCursorPos      ; set cursor position on oLed
    ld a, 129
    call oLed_printChar             ; print UDG 127


; now go round a loop waiting for user to EXIT

    ld b, 0                         ; B will be position counter

LOOP_HERE:                          
    MOSCALL $1E                     ; get IX pointer to keyvals, currently pressed keys

; check for ESC
    ld a, (ix + $0E)    
    bit 0, a                        ; check for ESC key pressed
    jp nz, EXIT_HERE                ; exit if pressed

; check for invert
    ld a, (ix + $04)    
    bit 5, a                        ; check for 'i' key pressed
    call nz, oLed_invert            ; invert if pressed

; check for normal         
    ld a, (ix + $0A)    
    bit 5, a                        ; check for 'n' key pressed
    call nz, oLed_normal            ; normal if pressed


; animate our packman character across the screen

    push bc                         ; store counters

    ld c, packman_row               ; C = y row (0-7)
    call oLed_setOledCursorPos           ; set cursor position on oLed
    ld a, ' '                       ; SPACE char
    call oLed_printChar             ; print UDG 128

    pop bc                          ; get counters back 

    inc b                           ; increase B position counter

    push bc                         ; store counters

    ld c, packman_row  
    call oLed_setOledCursorPos      ; set cursor position on oLed
    
    ld a,b                          ; we will toggle character only every 4 frames
    and 00000100b                   ; get one bit only
    or a                            ; clear any flags
    sra a                           ; shift right
    sra a                           ; shift right  

    or 130                          ; add 130

    call oLed_printChar             ; print UDG 130 or 131


    ld a, 00000100b
    call multiPurposeDelay          ; brief pause so not too fast

    pop bc                          ; get counters back

    ld a, b
    cp 121                          ; check if reached end of line yet
    jp nz, LOOP_HERE                ; move to next position if not

                                    ; else reset position and clear old character
    ld c, packman_row               ; C = y row (0-7)
    call oLed_setOledCursorPos      ; set cursor position on oLed
    ld a, ' '                       ; clear last character with a SPACE
    call oLed_printChar             ; print SPACE

    ld b,0                          ; reset position counter

    jp LOOP_HERE		              


; ------------------------------------

EXIT_HERE:

    call oLed_clearDisplay          ; clear oLed screen before srawing text, etc

    call i2c_close		            ; close the i2c port

    CLS                             ; leave screen clean after exit

    pop iy                          ; Pop all registers back from the stack
    pop ix
    pop de
    pop bc
    pop af
    ld hl,0                         ; Load the MOS API return code (0) for no errors.   
    
    ret                             ; Return to MOS

; ------------------------------------
;
;   i2c functions
;
; ------------------------------------

i2c_open:

    ld c, 3                         ; speed setting
    MOSCALL $1F                     ; open i2c bus
    ret

; ------------------------------------

i2c_close:

    MOSCALL $20                     ; close i2c bus
    ret 


; ------------------------------------
;
;   OLED FUNCTIONS
;
; ------------------------------------

; send config data to the oLed

oLed_initDisplay:
    ld b, 14                        ; 14 bytes of config data
    ld c, i2c_address
    ld hl, initString               ; data to send
    MOSCALL $21                     ; send the data
    ret 

initString:                         ; config commands - 14 bytes

    .db $00                         ; get started initial zero byte
    .db $ae                         ; Set Display OF
    .db $40                         ; Set start line (line #0)
    .db $a1                         ; Segment re-map (mirror mode)
    .db $c8                         ; Set scan direction (from COM0)
    .db $81                         ; SetContrastControl
    .db $80                         ; reset/mid level = $80
    .db $8d                         ; Charge pump enable
    .db $14                         ; Internal DC/DC
    .db $20                         ; Set Memory Addressing Mode:-
    .db $02                         ;   $02 Page mode ($00 = Horizontal mode)
    .db $a4                         ; Output follows RAM ($a5 all pixels ON test)
    .db $a6                         ; Set Normal (not inverse A7)
    .db $af                         ; Set display ON (normal mode)
    
; ------------------------------------
; sends a single command to the oLed

oLed_sendCommand:                   ; command is in A
    push bc
    push hl
    ld c, i2c_address               ; i2c address
    ld b, 2                         ; number of bytes to send
    ld hl, i2c_write_buffer         ; 'i2c_write_buffer' is where data to be sent is stored
    ld (hl), COMMAND_REG             
    inc hl
    ld (hl), a                       
    ld hl, i2c_write_buffer 
    MOSCALL $21                     ; send 2 bytes of command and data  
    pop hl
    pop bc

    ret 

; ------------------------------------
; sends a single data byte to the oLed
; note- after each display byte sent, the cursor position moves along one place
; and will wrap around on same line

oLed_sendData:                      ; data is in A
    push bc
    push hl
    ld c, i2c_address               ; i2c address
    ld b, 2                         ; number of bytes to send
    ld hl, i2c_write_buffer         ; 'i2c_write_buffer' is where data to be sent is stored
    ld (hl), DATA_REG             
    inc hl
    ld (hl), a                       
    ld hl, i2c_write_buffer 
    MOSCALL $21                     ; send 2 bytes of command and data  
    pop hl
    pop bc

    ret 

; ------------------------------------
; sets the oLed cursor position for next byte of data

oLed_setOledCursorPos:              ; x,y in B,C

    ld a, b 
    and 00001111b
    call oLed_sendCommand           ; send column lower nibble

    ld a, b 
    or a  
    rra
    rra
    rra
    rra
    and 00001111b
    or 00010000b
    call oLed_sendCommand           ; send column upper nibble

    ld a, c 
    or $B0
    call oLed_sendCommand           ; send row

    ret 

; ------------------------------------
;   Clear the screen
;   Go to start of each line and print a wholeline of spaces.
;   We need to send 1k of '0' data, but we are (currently) 
;   limited to 32 chars max at a time over i2c. This may change in
;   a later version of MOS.

oLed_clearDisplay:

    ld c, 0                         ; C is count of number of vertical lines (pages)
    
vert_Loop:
    ld b, 0
    push bc
    call oLed_setOledCursorPos      ; set the line (page) to erase. Position B,C
    pop bc

    push bc                         ; store C line count

    ld b, 6                         ; B is number of chunks sent per line (page)
horiz_Loop:                          ; send 32 blanks 5 times top clear a line
                                    ; if too many, they will just wrap around
    push bc                         ; store B loop counter
           

    ld c, i2c_address               ; i2c address
    ld b, 1                         ; number of bytes to send
    ld (hl), DATA_REG               ; tell it we will send some data
                    
    ld hl, i2c_write_buffer 
    MOSCALL $21                     ; send 1 byte command 

    ld c, i2c_address               ; i2c address
    ld b, 32                        ; number of bytes to send               
    ld hl, blankBytes32             ; pointer to an array of 32 x 0 bytes
    MOSCALL $21                     ; send the data 

    pop bc                          ; retrieve B loop counter
    djnz horiz_Loop                 ; go round again if not done 6 yet


    pop bc                          ; retrieve C line counter

    inc c                           ; increase line count
    ld a, c                         ; put row count into A
    cp 8                            ; check if we have done all 8 lines
    jr nz, vert_Loop                ; if not go round loop again

    ret


; ------------------------------------
;   print a zero terminated string of chars

oLed_printCharString:                    
    ld a,(hl)                       ; HL is a poi ter to the string to print
    or a                            ; quick way to check if it is a zero
    ret z                           ; if it is, then we are done
    push hl                         ; store HL as it will get destroyed in the 'printChar' function
    call oLed_printChar             ; print the current char
    pop hl                          ; get HL back again
    inc hl                          ; increase the pointer position
    jr oLed_printCharString         ; go round and check the next char


; ------------------------------------
;   print a single char

oLed_printChar:                     ; char to print is in A

                                    ; Need to find offset in the font data for our char:-
    sub 32                          ; first 32 bytes are non printing and not in our data, so dec by 32
    ld de, 6                        ; number of bytes per char
    call DE_Times_A                 ; calculate byte offset from start of data, result is in HL
    ld de,  fontBytes               ; grab the start of data
    add hl, de                      ; add to get offset into font data for our char into HL

    ld b, 6                         ; need to send out 6 bytes of data per ASCII font character

sendLoop:
    ld a, (hl)                      ; get byte of data
    inc hl                          ; increase font data pointer ready for next one
    call oLed_sendData              ; send the byte of data
    djnz sendLoop                   ; repeat 6 times

    ret


; ------------------------------------
;   invert display

oLed_invert:
    ld a, INVERT
    call oLed_sendCommand

    ret 

; ------------------------------------
;   normal display

oLed_normal:
    ld a, NORMAL
    call oLed_sendCommand

    ret 

; ------------------------------------
;
;   MATHS ROUTINES
;
; ------------------------------------

DE_Times_A:
;Inputs:
;     DE and A are factors
;Outputs:
;     A is not changed
;     B is 0
;     C is not changed
;     DE is not changed
;     HL is the product

     ld b,8          ;7           7
     ld hl,0         ;10         10
       add hl,hl     ;11*8       88
       rlca          ;4*8        32
       jr nc,$+3     ;(12|18)*8  96+6x
         add hl,de   ;--         --
       djnz $-5      ;13*7+8     99
     ret             ;10         10


; ------------------------------------
;
;   STRINGS AND DATA
;
; ------------------------------------

VDUdata:                            ; setup simple display
   
    .db 31, 0, 0, "Agon Light - i2c oLED display"
    .db 31, 0, 8, "Press and hold ESC to exit"

endVDUdata:


msgStr1:
    .db  "Agon Z80 Assembly", 0     ; text to print on oLed, zero terminated

msgStr2:
    .db  "SSD1306 oLed Display", 0  ; text to print on oLed, zero terminated

blankBytes32:
    .ds 32,0                        ; 32 bytes of 32 (space)

; ------------------------------------

i2c_read_buffer:                    ; to store data sent and recieved to i2c
    .ds 32,0                        ; allow 32 bytes even if not all needed

i2c_write_buffer:
    .ds 32,0

; ------------------------------------
;
;   Simple Standard Font - in ascii
;   5x8 pixel font, runs vertically
;   With 132x64 pixel oLed = 22x8 characters
;   Other widths could be defined
;   
; ------------------------------------

fontBytes:
;   standard ASCII
    .db    $00, $00, $00, $00, $00, $00 ; space ASCII 32
    .db    $00, $00, $00, $2f, $00, $00 ; !
    .db    $00, $00, $07, $00, $07, $00 ; "
    .db    $00, $14, $7f, $14, $7f, $14 ; #
    .db    $00, $24, $2a, $7f, $2a, $12 ; $
    .db    $00, $23, $13, $08, $64, $62 ; %
    .db    $00, $36, $49, $55, $22, $50 ; &
    .db    $00, $00, $05, $03, $00, $00 ; '
    .db    $00, $00, $1c, $22, $41, $00 ; (
    .db    $00, $00, $41, $22, $1c, $00 ; )
    .db    $00, $14, $08, $3e, $08, $14 ; *
    .db    $00, $08, $08, $3e, $08, $08 ; +
    .db    $00, $00, $00, $a0, $60, $00 ; ,
    .db    $00, $08, $08, $08, $08, $08 ; -
    .db    $00, $00, $60, $60, $00, $00 ; .
    .db    $00, $20, $10, $08, $04, $02 ; /
    .db    $00, $3e, $51, $49, $45, $3e ; 0
    .db    $00, $00, $42, $7f, $40, $00 ; 1
    .db    $00, $42, $61, $51, $49, $46 ; 2
    .db    $00, $21, $41, $45, $4b, $31 ; 3
    .db    $00, $18, $14, $12, $7f, $10 ; 4
    .db    $00, $27, $45, $45, $45, $39 ; 5
    .db    $00, $3c, $4a, $49, $49, $30 ; 6
    .db    $00, $01, $71, $09, $05, $03 ; 7
    .db    $00, $36, $49, $49, $49, $36 ; 8
    .db    $00, $06, $49, $49, $29, $1e ; 9
    .db    $00, $00, $36, $36, $00, $00 ; :
    .db    $00, $00, $56, $36, $00, $00 ; ;
    .db    $00, $08, $14, $22, $41, $00 ; <
    .db    $00, $14, $14, $14, $14, $14 ; =
    .db    $00, $00, $41, $22, $14, $08 ; >
    .db    $00, $02, $01, $51, $09, $06 ; ?
    .db    $00, $32, $49, $59, $51, $3e ; @
    .db    $00, $7c, $12, $11, $12, $7c ; A
    .db    $00, $7f, $49, $49, $49, $36 ; B
    .db    $00, $3e, $41, $41, $41, $22 ; C
    .db    $00, $7f, $41, $41, $22, $1c ; D
    .db    $00, $7f, $49, $49, $49, $41 ; E
    .db    $00, $7f, $09, $09, $09, $01 ; F
    .db    $00, $3e, $41, $49, $49, $7a ; G
    .db    $00, $7f, $08, $08, $08, $7f ; H
    .db    $00, $00, $41, $7f, $41, $00 ; I
    .db    $00, $20, $40, $41, $3f, $01 ; J
    .db    $00, $7f, $08, $14, $22, $41 ; K
    .db    $00, $7f, $40, $40, $40, $40 ; L
    .db    $00, $7f, $02, $0c, $02, $7f ; M
    .db    $00, $7f, $04, $08, $10, $7f ; N
    .db    $00, $3e, $41, $41, $41, $3e ; O
    .db    $00, $7f, $09, $09, $09, $06 ; P
    .db    $00, $3e, $41, $51, $21, $5e ; Q
    .db    $00, $7f, $09, $19, $29, $46 ; R
    .db    $00, $46, $49, $49, $49, $31 ; S
    .db    $00, $01, $01, $7f, $01, $01 ; T
    .db    $00, $3f, $40, $40, $40, $3f ; U
    .db    $00, $1f, $20, $40, $20, $1f ; V
    .db    $00, $3f, $40, $38, $40, $3f ; W
    .db    $00, $63, $14, $08, $14, $63 ; X
    .db    $00, $07, $08, $70, $08, $07 ; Y
    .db    $00, $61, $51, $49, $45, $43 ; Z
    .db    $00, $00, $7f, $41, $41, $00 ; [
    .db    $00, $02, $04, $08, $10, $20 ; \
    .db    $00, $00, $41, $41, $7f, $00 ; ]
    .db    $00, $04, $02, $01, $02, $04 ; ^
    .db    $00, $40, $40, $40, $40, $40 ; _
    .db    $00, $00, $01, $02, $04, $00 ; '
    .db    $00, $20, $54, $54, $54, $78 ; a
    .db    $00, $7f, $48, $44, $44, $38 ; b
    .db    $00, $38, $44, $44, $44, $20 ; c
    .db    $00, $38, $44, $44, $48, $7f ; d
    .db    $00, $38, $54, $54, $54, $18 ; e
    .db    $00, $08, $7e, $09, $01, $02 ; f
    .db    $00, $18, $a4, $a4, $a4, $7c ; g
    .db    $00, $7f, $08, $04, $04, $78 ; h
    .db    $00, $00, $44, $7d, $40, $00 ; i
    .db    $00, $40, $80, $84, $7d, $00 ; j
    .db    $00, $7f, $10, $28, $44, $00 ; k
    .db    $00, $00, $41, $7f, $40, $00 ; l
    .db    $00, $7c, $04, $18, $04, $78 ; m
    .db    $00, $7c, $08, $04, $04, $78 ; n
    .db    $00, $38, $44, $44, $44, $38 ; o
    .db    $00, $fc, $24, $24, $24, $18 ; p
    .db    $00, $18, $24, $24, $18, $fc ; q
    .db    $00, $7c, $08, $04, $04, $08 ; r
    .db    $00, $48, $54, $54, $54, $20 ; s
    .db    $00, $04, $3f, $44, $40, $20 ; t
    .db    $00, $3c, $40, $40, $20, $7c ; u
    .db    $00, $1c, $20, $40, $20, $1c ; v
    .db    $00, $3c, $40, $30, $40, $3c ; w
    .db    $00, $44, $28, $10, $28, $44 ; x
    .db    $00, $1c, $a0, $a0, $a0, $7c ; y
    .db    $00, $44, $64, $54, $4c, $44 ; z
    .db    $00, $00, $08, $77, $00, $00 ; {
    .db    $00, $00, $00, $7f, $00, $00 ; |
    .db    $00, $00, $77, $08, $00, $00 ; }
    .db    $00, $10, $08, $10, $08, $00 ; ~ ASCII 126

;   User defined graphics 6 pixels wide, 8 pixels tall   
    .db    $ff, $81, $81, $81, $81, $ff ; UDG 127 (BOX)
    .db    01001000b, 01001000b, 00111110b, 00111110b, 01001000b, 10001000b ; UDG 128 (MAN 1)
    .db    10000100b, 01001000b, 00111110b, 00111110b, 01001000b, 01010000b ; UDG 129 (MAN 2)
    .db    60, 126, 255, 231, 195, 66 ; UDG 130 packman open mouth
    .db    60, 126, 255, 255, 126, 60 ; UDG 131 packman shut mouth

; ------------------------------------
;
;   END
;
; ------------------------------------
