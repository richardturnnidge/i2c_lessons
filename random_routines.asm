; ---------------------------------------------
;
;	A SET OF RANDOM FUNCTION ROUTINES TO INCLUDE
;
; ---------------------------------------------

get_random_byte:	;returns A as random byte
     .db 3Eh     	;start of ld a,*
randSeed:
     .db 0
     push bc 

     ld c,a
     add a,a
     add a,c
     add a,a
     add a,a
     add a,c
     add a,83
     ld (randSeed),a
     pop bc
     ret

; ---------------------------------------------


; Fast RND
;
; An 8-bit pseudo-random number generator,
; using a similar method to the Spectrum ROM,
; - without the overhead of the Spectrum ROM.
;
; R = random number seed
; an integer in the range [0-255]
;
; R -> (33*R) mod 257
;
; S = R - 1
; an 8-bit unsigned integer

get_random_byte_v2:

 ld a, (seed)
 ld b, a 

 rrca ; multiply by 32
 rrca
 rrca
 xor 0x1f

 add a, b
 sbc a, 255 ; carry

 ld (seed), a
 ret

seed:
     .db 255