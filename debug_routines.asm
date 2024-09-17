; ---------------------------------------------
;
;	DEBUG ROUTINES
;
; ---------------------------------------------
	
debugA:				; debug A to screen as HEX byte pair at pos BC
	push af 
	ld (debug_char), a	; store A
				; first, print 'A=' at TAB 36,0
	ld a, 31		; TAB at x,y
	rst.lil $10
	ld a, b			; x=b
	rst.lil $10
	ld a,c			; y=c
	rst.lil $10		; put tab at BC position

	ld a, (debug_char)	; get A from store, then split into two nibbles
	and 11110000b		; get higher nibble
	rra
	rra
	rra
	rra			; move across to lower nibble
	add a,48		; increase to ascii code range 0-9
	cp 58			; is A less than 10? (58+)
	jr c, nextbd1		; carry on if less
	add a, 7		; add to get 'A' char if larger than 10
nextbd1:	
	rst.lil $10		; print the A char

	ld a, (debug_char)	; get A back again
	and 00001111b		; now just get lower nibble
	add a,48		; increase to ascii code range 0-9
	cp 58			; is A less than 10 (58+)
	jp c, nextbd2		; carry on if less
	add a, 7		; add to get 'A' char if larger than 10	
nextbd2:	
	rst.lil $10		; print the A char
	
	ld a, (debug_char)
	pop af 
	ret			; head back

debug_char: 	.db 0


; ---------------------------------------------

debugA_gr:				; debug A direct to screen as HEX byte pair 
	push af 
	ld (debug_char), a	; store A
				; first, print 'A=' at TAB 36,0


; 	ld a, 31		; TAB at x,y
; 	rst.lil $10
; 	ld a, b			; x=b
; 	rst.lil $10
; 	ld a,c			; y=c
; 	rst.lil $10		; put tab at BC position

	ld a, 25
	rst.lil $10
	ld a, 68                            ;  plot point
	rst.lil $10

	ld a, b                         ;  plot y
	rst.lil $10
	ld a, 0                             ;  plot x
	rst.lil $10

	ld a, c
	or a  
	rla
	rla
	rla
	rla
	rst.lil $10
	ld a, 0                             ;  plot y
	rst.lil $10

	ld a, 5                             ;  plot y
	rst.lil $10


	ld a, (debug_char)	; get A from store, then split into two nibbles
	and 11110000b		; get higher nibble
	rra
	rra
	rra
	rra			; move across to lower nibble
	add a,48		; increase to ascii code range 0-9
	cp 58			; is A less than 10? (58+)
	jr c, nextgd1		; carry on if less
	add a, 7		; add to get 'A' char if larger than 10
nextgd1:	
	rst.lil $10		; print the A char

	ld a, (debug_char)	; get A back again
	and 00001111b		; now just get lower nibble
	add a,48		; increase to ascii code range 0-9
	cp 58			; is A less than 10 (58+)
	jp c, nextgd2		; carry on if less
	add a, 7		; add to get 'A' char if larger than 10	
nextgd2:	
	rst.lil $10		; print the A char
	
	ld a, (debug_char)
	pop af 
	ret			; head back



; ---------------------------------------------

printBin:
				; take A as number and print out as binary, B,C as X,Y position
				; take D as number of bits to do
	push af 

	ld a, 31		; TAB at x,y
	rst.lil $10
	ld a, b			; x=b
	rst.lil $10
	ld a,c			; y=c
	rst.lil $10		; put tab at BC position

	pop af 


	ld b, d
	ld hl, binString
rpt:
	ld (hl), 48 	; ASCII 0 is 48, 1 is 49 ; reset first

	bit 7, a
	jr z, nxt
	ld (hl), 49
nxt:	
	inc hl	; next position in string
	rla 
	djnz rpt


	ld hl, printStr
	ld bc, endPrintStr - printStr

	rst.lil $18


	ret

			; print binary
printStr:
binString:	.db 	"00000000"
endPrintStr:

; ---------------------------------------------


debugInst:			; debug A to screen as HEX byte pair at current pos
	push af 
	ld (debug_char), a	; store A
				; first, print 'A=' at TAB 36,0

	ld a, (debug_char)	; get A from store, then split into two nibbles
	and 11110000b		; get higher nibble
	rra
	rra
	rra
	rra			; move across to lower nibble
	add a,48		; increase to ascii code range 0-9
	cp 58			; is A less than 10? (58+)
	jr c, nextin1		; carry on if less
	add a, 7		; add to get 'A' char if larger than 10
nextin1:	
	rst.lil $10		; print the A char

	ld a, (debug_char)	; get A back again
	and 00001111b		; now just get lower nibble
	add a,48		; increase to ascii code range 0-9
	cp 58			; is A less than 10 (58+)
	jp c, nextin2		; carry on if less
	add a, 7		; add to get 'A' char if larger than 10	
nextin2:	
	rst.lil $10		; print the A char
	
	ld a, (debug_char)
	pop af 
	ret			; head back

; ---------------------------------------------


debugDec:		; debug A to screen as 3 char string pos

	push af
	ld a, 48
	ld (answer),a 
	ld (answer+1),a 
	ld (answer+2),a 	; reset to default before starting

	        ; is it bigger than 200?
	pop af

	ld (base),a         ; save

	cp 199
	jr c,_under200      ; not 200+
	sub a, 200
	ld (base),a         ; sub 200 and save

	ld a, 50            ; 2 in ascii
	ld (answer),a
	jr _under100

_under200:
	cp 99
	jr c,_under100      ; not 200+
	sub a, 100
	ld (base),a         ; sub 200 and save

	ld a, 49            ; 1 in ascii
	ld (answer),a
	jr _under100


_under100:
	ld a, (base)
	ld c,a
	ld d, 10
	call C_Div_D

	add a, 48
	ld (answer + 2),a

	ld a, c
	add a, 48
	ld (answer + 1),a


	ld hl, debugOut                      ; address of string to use
	ld bc, endDebugOut - debugOut         ; length of string
	rst.lil $18
	ret 


debugOut:
answer:         .db     "000"		; string to output
endDebugOut:

base:       	.db     0		; used in calculations


; -----------------

C_Div_D:
;Inputs:
;     C is the numerator
;     D is the denominator
;Outputs:
;     A is the remainder
;     B is 0
;     C is the result of C/D
;     D,E,H,L are not changed
;
	ld b,8
	xor a
	sla c
	rla
	cp d
	jr c,$+4
	inc c
	sub d
	djnz $-8
	ret


; -----------------

;	EXPERIMENTAL 'PRINTER' OUTPUT


debugString:                            ; print zero terminated string
	ld a, 2 
	rst.lil $10			; enable 'printer'
	ld a, 21 
	rst.lil $10			; disable vdu commands

	ld a,(hl)
	or a
	ret z
	RST.LIL 10h
	inc hl
	jr debugString

	ld a, 6 
	rst.lil $10			; enable vdu commands
	ld a, 21 
	rst.lil $10			; disable 'printer'

	ret


; ---------------------------------------------
;
;	SERIAL PORT DEBUGGING
;
; ---------------------------------------------

    macro DEBUGMSG  whichMsg
        if DEBUGGING            ; only gets assembled if DEBUGGING is true, else assembles nothing
            push af
            push hl             ; HL and A are used, so save for when we are done

            ld a, 2
            rst.lil $10         ; enable 'printer'
            ld a, 21
            rst.lil $10         ; disable screen

            ld hl, whichMsg
            call printString

            ld a, 6
            rst.lil $10         ; re-enable screen
            ld a, 3
            rst.lil $10         ; disable printer

            pop hl  
            pop af
        endif
    endmacro

; ---------------------------------------------

debugRegisters:
    ; only gets assembled if DEBUGGING is true
    ; else returns immediately

 ;   if DEBUGGING
        push af
        push hl             ; HL and A are used, so save for when we are done

        push af
        push hl             ; here just keeping for this routine

        ld a, 2
        rst.lil $10         ; enable 'printer'
        ld a, 21
        rst.lil $10         ; disable screen

        ld hl, hlReg
        call printString

        pop hl
        ld (temp),hl
        ld a, (temp+2) 
        call debugInst
        ld a, h 
        call debugInst
        ld a, l 
        call debugInst
  


        ld hl, bcReg
        call printString

        ld (temp),bc
        ld a, (temp+2) 
        call debugInst
        ld a, b 
        call debugInst
        ld a, c 
        call debugInst


        ld hl, deReg
        call printString

        ld (temp),de
        ld a, (temp+2) 
        call debugInst
        ld a, d 
        call debugInst
        ld a, e 
        call debugInst


        ld hl, aReg
        call printString

        pop af
        call debugInst

        ld hl, CR
        call printString


        ld a, 6
        rst.lil $10         ; re-enable screen
        ld a, 3
        rst.lil $10         ; disable printer

        pop hl 
        pop af

 ;   endif

    ret

temp:       .db 0,0,0       ; used to store Upper bytes of registers


CR:         .db "\r\n",0
hlReg:      .db "(U)HL = ",0
bcReg:      .db "   (U)BC = ",0
deReg:      .db "   (U)DE = ",0
aReg:       .db "   A = ",0




printString:            ; print zero terminated string
	ld a,(hl)
	or a
	ret z
	RST.LIL 10h
	inc hl
	jr printString












