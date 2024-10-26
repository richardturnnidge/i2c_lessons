;   LCD1602 i2c routines
;   Richard Turnnidge 2024 
;   This module displays better on 5v

;   USEFUL ROUTINES IN THIS CODE:
;
;   LCD_INIT - prep the LCD system
;   LCD_SEND_COMMAND - send the command stored in A
;   LCD_SEND_DATA - send the data stored in A
;   LCD_TABTO - TAB to B,C
;   LCD_PRINT_STRING - print at current cursor position until $FF character
;   LCD_CREATE_UDG - create a UDG from data at HL


    .assume adl=1                    ; ez80 ADL memory mode
    .org $40000                      ; load code here


    jp START_HERE                    ; jump to start of code

    .align 64                        ; MOS header
    .db "MOS",0,1     

; ---------------------------------------------
; some useful macros. Need to be included first
; ---------------------------------------------

    macro DELAY_1
    ld a, 00000010b
    call multiPurposeDelay
    endmacro

    macro DELAY_2
    ld a, 00000100b
    call multiPurposeDelay
    endmacro

    macro DELAY_3
    ld a, 0001000b
    call multiPurposeDelay
    endmacro

    macro DELAY_4
    ld a, 00100000b
    call multiPurposeDelay
    endmacro

    macro DELAY_5
    ld a, 01000000b
    call multiPurposeDelay
    endmacro

    macro DELAY_6
    ld a, 10000000b
    call multiPurposeDelay
    endmacro

    macro CLS
    ld a, 12
    rst.lil $10
    endmacro

    macro MOSCALL arg1
    ld a, arg1
    rst.lil $08
    endmacro

; ---------------------------------------------
; include any other useful files
; ---------------------------------------------

    include "delay_routines.asm"

; ---------------------------------------------
; define configuration constants
; ---------------------------------------------

i2c_address:        equ $27          ; this is the default for most i2c LCD controllers, but can be modified on board
LCD_LINE1:          equ $80          ; LCD default print position line 1
LCD_LINE2:          equ $C0          ; LCD default print position line 2
LCD_CLEAR:          equ $01          ; LCD clear display
CHAR_ALIEN:         equ $00          ; LCD custom character id
CHAR_BOX:           equ $01          ; LCD custom character id

; ---------------------------------------------
; MAIN CODE HERE
; ---------------------------------------------


START_HERE:
            
    push af                          ; store all the registers for later when we exit
    push bc
    push de
    push ix
    push iy

    CLS                             ; just clear our Agon display
      

    ld hl, VDUdata
    ld bc, endVDUdata - VDUdata
    rst.lil $18                     ; print simple info message to display


; open the i2c port and prepare the LCD 

    call i2c_open                   ; open i2c port
    DELAY_3

    call LCD_INIT                   ; init the LCD panel with 4 bit comms
    DELAY_3

; add some custon characters to the LCD memory

    ld hl, data_alien               ; setup custom chars
    call LCD_CREATE_UDG
    DELAY_6                         ; give time for RAM to be written

    ld hl, data_box                 ; setup custom chars
    call LCD_CREATE_UDG
    DELAY_6                         ; give time for RAM to be written

; set the default position of the first character to print

    ld a, LCD_CLEAR                 ; clear LCD display
    call LCD_SEND_COMMAND
    DELAY_2
    
    ld a, LCD_LINE1                 ; set cursor to 0,0
    call LCD_SEND_COMMAND
    DELAY_2
    
; now print some things to the LCD

    ld a, '0'                       ; print 0
    call LCD_SEND_DATA              ; note that cursor position moves on automatically...

    ld a, '1'                       ; print 1 
    call LCD_SEND_DATA

    ld a, '2'                       ; print 2 
    call LCD_SEND_DATA

    ld a, '3'                       ; print 3 
    call LCD_SEND_DATA

    ld a, ' '                       ; print SPACE 
    call LCD_SEND_DATA

    ld a, CHAR_BOX                  ; print custom char as named 
    call LCD_SEND_DATA

    ld a, LCD_LINE2                 ; go to line 2
    call LCD_SEND_COMMAND

    ld hl, msg2print                ; print a 255 terminated message string
    call LCD_PRINT_STRING

    ld b, 0
    ld c, 15
    call LCD_TABTO                  ; tab to new position of B (0-1), C (0-15)


    ld a, CHAR_ALIEN                ; print custom char 0 (LCD_ALIEN)
    call LCD_SEND_DATA


; just wait here until ESC key pressed, then EXIT

LOOP_HERE:
    MOSCALL $1E                     ; get IX pointer to keyvals, currently pressed keys
    ld a, (ix + $0E)    
    bit 0, a                        ; check for ESC key pressed
    jp nz, EXIT_HERE                ; exit if pressed


    jp LOOP_HERE		              

; ---------------------------------------------

EXIT_HERE:

    ld a, LCD_CLEAR                 ; clear display
    call LCD_SEND_COMMAND

    CLS
    call i2c_close                  ; close the i2c port

    pop iy                          ; Pop all registers back from the stack
    pop ix
    pop de
    pop bc
    pop af
    ld hl,0                         ; Load the MOS API return code (0) for no errors.   
    
    ret                             ; Return to MOS

; ---------------------------------------------

i2c_open:

    ld c, 3                         ; speed setting
    MOSCALL $1F                     ; open i2c call
    ret

; ---------------------------------------------

i2c_close:

    MOSCALL $20                     ; close i2c call
    ret 

; ---------------------------------------------
;
; LCD specific routines
;
; ---------------------------------------------

; Print a $FF terminated string

LCD_PRINT_STRING:                   ; assume $FF is delimiter, can't use 0 as that is code for first custom character
                                    ; HL is pointer to string data
    ld a,(hl)                       ; load byte into A
    cp $FF                          ; check if delimiter $FF
    ret z                           ; exit if it is
    call LCD_SEND_DATA              ; if not $FF then send a character of data
    inc hl                          ; move on to next byte of data
    jr LCD_PRINT_STRING             ; loop round again


; ---------------------------------------------
; create custom char

LCD_CREATE_UDG:                 ; arrive with HL containing the pointer to the data

    ld a, (hl)                  ; first byte is the RAM address
    call LCD_SEND_COMMAND       ; store data in first postion in RAM
    inc hl                      ; HL now points to start of 8 bytes of data
    ld b, 8                     ; going to loop 8 times

char_loop:
    ld a, (hl)                  ; get byte of data
    call LCD_SEND_DATA
    inc hl  
    djnz char_loop              ; loop round 8 times

    ret      

; ---------------------------------------------
; set cursor to line B (0 or 1), column C (0 to 15)

LCD_TABTO:                      

    ld a, LCD_LINE1                ; memory of first line, first char
    add a,c 
    or a                           ; clear flags
    rl b                           ; x 2    
    rl b                           ; x 4
    rl b                           ; x 8    
    rl b                           ; x 16
    rl b                           ; x 32    
    rl b                           ; x 64
    or b                           ; add to line 1 address

    call LCD_SEND_COMMAND

    ret  

; ---------------------------------------------
; these initialisation commands set the LCD in 4bit mode and get the screen ready
; don't ask what they all do, they are just needed!
; ---------------------------------------------

LCD_INIT:


    ld a, $33
    call LCD_SEND_COMMAND

    DELAY_3

    ld a, $32
    call LCD_SEND_COMMAND

    DELAY_3

    ld a, $06
    call LCD_SEND_COMMAND

    DELAY_3

    ld a, $0c
    call LCD_SEND_COMMAND

    DELAY_3

    ld a, $28
    call LCD_SEND_COMMAND

    DELAY_3

    ld a, $01
    call LCD_SEND_COMMAND

    DELAY_3

    ret 

; ---------------------------------------------
; sending data or commands to the LCD
; ---------------------------------------------

; both commands are almost the same with one bit/pin different (P0)

; pins/bits
; P7  P6  P5  P4    P3      P2          P1          P0
; |<-  DATA  ->|    LED(1)  Enable(1)   R(1)/W(0)   Cmd(0)/Data(1)

; each byte has 2 nibbles, BBBBCCCC
; this is split and each nibble is sent seperately

; Then, for each nibble sent, a whole byte is used, again split into twqo nibbles:
; lower nibble is command data
; upper nibble is the data to send
; 1 command or data byte will need 4 communication bytes sent.
; each nibble (HL) is sent, once with enable flag set, once without.
; eg. if A is: 11110000b
; H1 = BBBB (B) + CMD, eg: 1111 1100 (enable set)
; H2 = BBBB (B) + CMD, eg: 1111 1000 (enable not set)
; L1 = CCCC (C) + CMD, eg: 0000 1100 (enable set)
; L2 = CCCC (C) + CMD, eg: 0000 1000 (enable not set)
; 
; H1 = BBBB + 1110 (E)
; H2 = BBBB + 1010 (A)
; L1 = CCCC + 1110 (E)
; L2 = CCCC + 1010 (A)
; 

; bit 0 is command/data data=1, cmd=0 RS register select
; bit 1 is 0=read, 1=write
; bit 2 is enable. 1=data available
; bit 3 is backlight 1=on, 2=off

; HIGH nibble needs to be sent first, LOWER nibble second

; ---------------------------------------------

LCD_SEND_COMMAND:                   ; arrive with command in A, which we split into BC. 
                                    ; B will store upper nibble, C lower nibble

    push hl 
    push bc 


    ld c, a                         ; store A for moment
    and $F0                         ; keep top nibble and reset lower nibble
    ld b, a                         ; store result in B. eg. 11110000, UPPPER  nibble is in B

    ld a, c                         ; get original cmd back
    sla a
    sla a
    sla a
    sla a                           ; get lower 4 bits into top 4 bits
    and $F0                         ; keep top nibble and reset lower nibble  
    ld c,a                          ; store LOWER nibble into C                       

    ld hl, i2c_write_buffer

    ld a, b 
    or $0C 
    ld (hl), a 
    inc hl 

    ld a, b 
    or $08 
    ld (hl), a 
    inc hl 

    ld a, c 
    or $0C 
    ld (hl), a 
    inc hl 

    ld a, c 
    or $08 
    ld (hl), a 

    ld c, i2c_address               ; i2c address (default $48)
    ld b, 4                         ; number of bytes to send
    ld hl, i2c_write_buffer         ; 'i2c_write_buffer' is where data to be sent is stored
    MOSCALL $21                     ; send x bytes of data

    pop bc 
    pop hl  

    ret 

; ---------------------------------------------

LCD_SEND_DATA:                      ; arrive with data in A, which we split into BC. 
                                    ; B will store upper nibble, C lower nibble

    push hl 
    push bc 

    ld c, a                         ; store A for moment
    and $F0                         ; mask out top nibble with 1111
    ld b, a                         ; store result in B

    ld a, c                         ; get original cmd back
    sla a
    sla a
    sla a
    sla a                           ; get lower 4 bits into top 4 bits
    and $F0                         
    ld c,a                          ; store LOWER nibble into C   

    ld hl, i2c_write_buffer

    ld a, b 
    or $0D 
    ld (hl), a 
    inc hl 

    ld a, b 
    or $09 
    ld (hl), a 
    inc hl 

    ld a, c 
    or $0D 
    ld (hl), a 
    inc hl 

    ld a, c 
    or $09 
    ld (hl), a 

    ld c, i2c_address               ; i2c address (default $48)
    ld b, 4                         ; number of bytes to send
    ld hl, i2c_write_buffer         ; 'i2c_write_buffer' is where data to be sent is stored
    MOSCALL $21                     ; send x bytes of data

    pop bc 
    pop hl  

    ret 


; ---------------------------------------------
; custom char data
; ---------------------------------------------

data_alien:
    .db     $40                 ; address of char character in RAM. Starts at $40 and goes up 8 chars of 8 bytes each
                                ; they are printed with ascii codes 0-7

    .db     00010001b           ; 8 bytes of char data
    .db     00001110b           ; 5 pixels wide, 8 pixels high
    .db     00010001b           ; use lowest bits for the 5 pixels
    .db     00010001b           
    .db     00001110b           
    .db     00001010b
    .db     00010001b
    .db     00010001b   

data_box:
    .db     $48                 ; address of char character in RAM. Starts at $40 and goes up 8 chars of 8 bytes each
                                ; they are printed with ascii codes 0-7

    .db     00011111b           ; 8 bytes of char data
    .db     00010001b           ; 5 pixels wide, 8 pixels high
    .db     00010001b           ; use lowest bits for the 5 pixels
    .db     00010001b           
    .db     00010001b           
    .db     00010001b
    .db     00010001b
    .db     00011111b   


; ---------------------------------------------
; display data
; ---------------------------------------------

VDUdata:                            ; setup simple display

    .db 31, 0, 0, "Agon Light - 1602 LCD i2c test"
    .db 31, 0, 8, "Press Esc to exit"

endVDUdata:

msg2print:    
    .db "Agon Light 2", $FF 

; ---------------------------------------------
; i2c data
; ---------------------------------------------

i2c_read_buffer:		            ; to store data sent and recieved to i2c
    .ds 32,0

i2c_write_buffer:
    .ds 32,0

  