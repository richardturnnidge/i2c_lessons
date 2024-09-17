;   ADS1115 i2c Anaog to Digital converter
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
; define configuration defaults

input_channel:      equ 01000000b     ; either: 01000000b, 01010000b, 01100000b, 01110000b for A0-A3 single inputs

i2c_address:        equ $48           ; either: $48, $49, $4A or $4B

adc_gain:           equ 00000010b     ; either: 00000000b, 00000010b, 00000100b, 00000110b, 00001000b, 00001010b, 00001100b or 00001110b

sample_rate:        equ 10100000b     ; either: 000 to 111 at bits 7-5

comparitor:         equ 00000011b     ; from: 00-11. 11 is turned off

configReg:          equ 00000001b     ; value for configuration register
    
conversionReg:      equ 00000000b     ; value for conversion register


; ------------------

start_here:
            
    push af                          ; store all the registers for later when we exit
    push bc
    push de
    push ix
    push iy

    SET_MODE 8		                ; screen mode 8 for simplicity         

    ld hl, VDUdata
    ld bc, endVDUdata - VDUdata
    rst.lil $18                     ; setup the display

    call hidecursor                 ; hide the cursor so it doesn't keep flickering
    call i2c_open                   ; need to setup i2c port

LOOP_HERE:
    MOSCALL $1E                     ; get IX pointer to keyvals, currently pressed keys
    ld a, (ix + $0E)    
    bit 0, a                        ; check for ESC key pressed
    jp nz, EXIT_HERE                ; exit if pressed

    ld a, 00001000b               
    call multiPurposeDelay          ; wait a bit so display doesn't flicker

    call i2c_sendAdcConfig          ; send config settings to ADC1115

    ld a, 00000100b                
    call multiPurposeDelay          ; wait a bit or results tend to be incorrect
   
    call i2c_readAdc                ; read data from ADC1115
    call displayResult              ; show results on the screen

    jp LOOP_HERE		              


; ------------------

EXIT_HERE:

    call i2c_close		            ; close the i2c port
    call showcursor                 ; get the cursor back

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
    MOSCALL $1F                     ; open i2c call
    ret

; ------------------

i2c_close:

    MOSCALL $20                     ; close i2c call
    ret 

 ; ------------------

i2c_sendAdcConfig:

    ld hl, i2c_write_buffer         ; the data to send is stored at HL

    ; We send 3 configuration bytes, which are stored at 'i2c_write_buffer', pointed to by HL
    ; 1st byte says we are writing to the Config register
    ; 2nd and 3rd bytes are the actual configuration data


    ; 1st Byte
    ld (hl), configReg		        ; state that we are sending to config register   


    ; 2nd Byte - Write the MSB of Config Register Bits 15:8
    ; Bit  15      0=No effect, 1=Begin Single Conversion (in power down mode)
    ; Bits 14:12   How to configure A0 to A3 (comparitor or single ended)
    ; Bits 11:9    Programmable Gain 000=6.144v 001=4.096v 010=2.048v.. 111=0.256v
    ; Bit  8       0=Continuous conversion mode, 1=Power down single shot

    ld a, input_channel             ; input value
    or adc_gain                     ; add the gain value

    inc hl                          ; point HL to next storage byte
    ld (hl), a                      ; 2nd byte is MSB of Config reg to write 

    ; 3rd Byte - Write the LSB of Config Register Bits 7:
    ; Bits 7:5 Data Rate (Samples per second) 000=8, 001=16, 010=32, 011=64
    ;          100=128, 101=250, 110=475, 111=860
    ; Bit  4   Comparitor Mode 0=Traditional, 1=Window
    ; Bit  3   Comparitor Polarity 0=low, 1=high
    ; Bit  2   Latching 0=No, 1=Yes
    ; Bits 1:0 Comparitor # before Alert pin goes high
    ;          00=1, 01=2, 10=4, 11=Disable this feature

    ld a, sample_rate               ; set to sample rate
    or comparitor                   ; add compartor (disable)
                                    ; ignore bits 2-4, leave at 0

    inc hl                          ; point HL to next storage byte
    ld (hl), a                      ; 3rd byte is LSB of Config reg to write

                                    ; send the 3 bytes
    ld c, i2c_address               ; i2c address ($48 is default)
    ld b, 3                         ; number of bytes to send
    ld hl, i2c_write_buffer     
    MOSCALL $21                     ; send the i2c data

    ret 

; ------------------

i2c_readAdc:
                                    ; first, write to the Address Pointer register
    ld c, i2c_address               ; i2c address (default $48)
    ld b, 1                         ; number of bytes to send
    ld hl, i2c_write_buffer         ; 'i2c_write_buffer' is where data to be sent is stored
    ld (hl), conversionReg          ; sending $00 says we want to read from the conversion register
    MOSCALL $21                     ; send 1 byte of data

    ld a, 00000100b                     
    call multiPurposeDelay          ; wait a bit or results tend to be incorrect

    ld c, i2c_address   		    ; i2c address (default $48)
    ld b,2			                ; number of bytes to receive
    ld hl, i2c_read_buffer          ; results to get stored here
    MOSCALL $22                     ; ask for 2 bytes data to be read
   
    ret 

; ------------------

displayResult:

    ld b, 7                         ; x position
    ld c, 4                         ; y position
    ld a, (i2c_read_buffer)         ; 1st byte from read buffer
    call debugA                     ; print byte in HEX format at x,y

    ld b, 12                        ; x position
    ld c, 4                         ; y position
    ld a, (i2c_read_buffer + 1)     ; 2nd byte from read buffer
    call debugA                     ; print byte in HEX format at x,y

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

    .db 23, 0, 192, 0		        ; Non scaled graphics mode
   
    .db 31, 0, 0, "Agon Light - ADS1115 i2c test"

    .db 31, 0, 2, "       MSB  LSB"
    .db 31, 0, 4, "Value:"

    .db 31, 0,8, "Press Esc to exit"

endVDUdata:

i2c_read_buffer:		            ; to store data sent and recieved to i2c
    .ds 32,0

i2c_write_buffer:
    .ds 32,0

  