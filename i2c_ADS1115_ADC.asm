;   ADS1115 i2c Analog to Digital converter
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
; define configuration defaults. See later notes for bits used for each setting

i2c_address:        equ $48           ; either: $48, $49, $4A or $4B

ADS_input_channel:  .db 01000000b     ; either: 01000000b, 01010000b, 01100000b, 01110000b for A0-A3 single inputs

ADS_channel0:       equ 01000000b     ; defined here for use later is needed
ADS_channel1:       equ 01010000b     ; these values are for sinlge channel reads
ADS_channel2:       equ 01100000b
ADS_channel3:       equ 01110000b

ADS_adc_gain:       equ 00000010b     ; this is the range of the read result
                                      ; assuming 3.3v   value is from $00-$XX (MSB)
                                      ; 00000000b, scale = 6.1v scale $00-$43 (at full turn)
                                      ; 00000010b, scale = 4.1v scale $00-$65 (at full turn)
                                      ; 00000100b, scale = 2.0v scale $00-$7F (max at about 2/3 turn)
                                      ; 00000110b, scale = 1.0v scale $00-$7F (max at about 1/3 turn)
                                      ; or possible but not useful: 00001000b, 00001010b, 00001100b or 00001110b

ADS_sample_rate:    equ 10100000b     ; either: 000 to 111 at bits 7-5

ADS_comparitor:     equ 00000011b     ; from: 00-11. 11 is turned off

ADS_configReg:      equ 00000001b     ; command to set configuration register
    
ADS_conversionReg:  equ 00000000b     ; memory address for conversion register (readings)


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
    rst.lil $18                     ; setup the display

    call hidecursor                 ; hide the cursor so it doesn't keep flickering
    call i2c_open                   ; need to setup i2c port

    ld a, ADS_channel0
    ld (ADS_input_channel), a       ; set the input channel to use

    call i2c_sendAdcConfig          ; send config settings to ADC1115

LOOP_HERE:
    MOSCALL $1E                     ; get IX pointer to keyvals, currently pressed keys
    ld a, (ix + $0E)    
    bit 0, a                        ; check for ESC key pressed
    jp nz, EXIT_HERE                ; exit if pressed

    ld a, 00000100b                
    call multiPurposeDelay          ; wait a bit or results tend to be incorrect
   
    call i2c_readAdc                ; read data from ADC1115
    call displayResult              ; show results on the screen

    jp LOOP_HERE		              


; ------------------

EXIT_HERE:

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
    ld (hl), ADS_configReg	        ; state that we are sending to config register   
    inc hl                          ; point HL ready for next storage byte

    ; 2nd Byte - Write the MSB of Config Register Bits 15:8
    ; Bit  15      0=No effect, 1=Begin Single Conversion (in power down mode)
    ; Bits 14:12   Input channel: How to configure A0 to A3 (comparitor or single ended)
    ; Bits 11:9    Programmable Gain 000=6.144v 001=4.096v 010=2.048v.. 111=0.256v
    ; Bit  8       0=Continuous conversion mode, 1=Power down single shot

    ld a, (ADS_input_channel)       ; input value
    or ADS_adc_gain                 ; add the gain value
    ld (hl), a                      ; 2nd byte is MSB of Config reg to write 
    inc hl                          ; point HL ready for next storage byte

    ; 3rd Byte - Write the LSB of Config Register Bits 7:
    ; Bits 7:5 Data Rate (Samples per second) 000=8, 001=16, 010=32, 011=64
    ;          100=128, 101=250, 110=475, 111=860
    ; Bit  4   Comparitor Mode 0=Traditional, 1=Window
    ; Bit  3   Comparitor Polarity 0=low, 1=high
    ; Bit  2   Latching 0=No, 1=Yes
    ; Bits 1:0 Comparitor # before Alert pin goes high
    ;          00=1, 01=2, 10=4, 11=Disable this feature

    ld a, ADS_sample_rate           ; set to sample rate
    or ADS_comparitor               ; add compartor (disable)
                                    ; ignore bits 2-4, leave at 0
    ld (hl), a                      ; 3rd byte is LSB of Config reg to write

                                    ; send the 3 bytes
    ld c, i2c_address               ; i2c address ($48 is default)
    ld b, 3                         ; number of bytes to send
    ld hl, i2c_write_buffer         ; set HL to start of data to send
    MOSCALL $21                     ; send the i2c data

    ret 

; ------------------

i2c_readAdc:
                                    ; first, write to the Address Pointer register
    ld c, i2c_address               ; i2c address (default $48)
    ld b, 1                         ; number of bytes to send
    ld hl, i2c_write_buffer         ; 'i2c_write_buffer' is where data to be sent is stored
    ld (hl), ADS_conversionReg      ; sending $00 says we want to read from the conversion register
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

  