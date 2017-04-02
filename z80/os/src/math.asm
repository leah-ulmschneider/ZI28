;; Contains advanced math routines
;;
;; Based on: http://www.ticalc.org/pub/83/asm/source/routines/math32.inc
.list


add32:
;; Add two 32-bit numbers
;;
;; Input:
;; : (hl), (de) - 32-bit numbers
;;
;; Output:
;; : (hl) = (hl) + (de)
;;
;; Destroyed:
;; : a, b, de, hl

	;clear the carry flag
	or a

.func adc32:
;; Add two 32-bit numbers and the carry bit
;;
;; Input:
;; : (hl), (de) - 32-bit numbers
;;
;; Output:
;; : (hl) = (hl) + (de) + cf
;;
;; Destroyed:
;; : a, b, de, hl

	ld b, 4
loop:
	ld a, (de)
	adc a, (hl)
	ld (hl), a
	inc hl
	inc de
	djnz loop
	ret
.endf ;add32


sub32:
;; Subtract two 32-bit numbers
;;
;; Input:
;; : (hl), (de) - 32-bit numbers
;;
;; Output:
;; : (hl) = (hl) - (de)
;;
;; Destroyed:
;; : a, b, de, hl

	;clear the carry flag
	or a

.func sbc32:
;; Subtract two 32-bit numbers and the carry bit
;;
;; Input:
;; : (hl), (de) - 32-bit numbers
;;
;; Output:
;; : (hl) = (hl) - (de) - cf
;;
;; Destroyed:
;; : a, b, de, hl

	ld b, 4
loop:
	ld a, (de)
	sbc a, (hl)
	ld (de), a
	inc de
	inc hl
	djnz loop
	ret
.endf ;sub32


.func inc32:
;; Increment a 32-bit number by 1
;;
;; Input:
;; : (hl) - 32-bit number
;;
;; Output:
;; : (hl) = (hl) + 1
;;
;; Destroyed:
;; : hl

	inc (hl)
	ret nz
	inc hl
	
	inc (hl)
	ret nz
	inc hl

	inc (hl)
	ret nz
	inc hl

	inc (hl)
	ret
.endf


.func lshiftbyte32:
;; Shift a 32-bit number left by 1 byte
;;
;; Input:
;; : (hl) - 32-bit number
;;
;; Output:
;; : (hl) = (hl) << 8
;;
;; Destroyed:
;; : a, hl

	inc hl
	inc hl

	ld a, (hl)
	inc hl
	ld (hl), a
	dec hl
	dec hl

	ld a, (hl)
	inc hl
	ld (hl), a
	dec hl
	dec hl

	ld a, (hl)
	inc hl
	ld (hl), a
	dec hl
	ld (hl), 0
	ret
.endf


.func lshift32:
;; Shift a 32-bit number left by 1 bit
;;
;; Input:
;; : (hl) - 32-bit number
;;
;; Output:
;; : (hl) = (hl) << 1
;; : carry flag
;;
;; Destroyed:
;; : a, hl

	or a
	rl (hl)
	inc hl
	rl (hl)
	inc hl
	rl (hl)
	inc hl
	rl (hl)
	ret
.endf


.func rshiftbyte32:
;; Shift a 32-bit number right by 1 byte
;;
;; Input:
;; : (hl) - 32-bit number
;;
;; Output:
;; : (hl) = (hl) >> 8
;;
;; Destroyed:
;; : a, hl

	inc hl
	ld a, (hl)
	dec hl
	ld (hl), a
	inc hl

	inc hl
	ld a, (hl)
	dec hl
	ld (hl), a
	inc hl

	inc hl
	ld a, (hl)
	dec hl
	ld (hl), a
	inc hl

	ld (hl), 0
	ret
.endf


.func rshift32:
;; Shift a 32-bit number right by 1 bit
;;
;; Input:
;; : (hl) - 32-bit number
;;
;; Output:
;; : (hl) = (hl) >> 1
;; : carry flag
;;
;; Destroyed:
;; : a, hl

	or a
	inc hl
	inc hl
	inc hl

	rr (hl)
	dec hl
	rr (hl)
	dec hl
	rr (hl)
	dec hl
	rr (hl)
	ret
.endf


.func ld8:
;; Load an 8-bit number into a 32-bit pointer
;;
;; Input:
;; : a - 8-bit number
;; : hl - 32-bit pointer
;;
;; Output:
;; : (hl) = a
;;
;; Destroyed:
;; : b, de, hl

	;save hl
	ld d, h
	ld e, l

	;clear (hl)
	call clear32
	ld (de), a
	ret
.endf ;ld8


.func ld16:
;; Load a 16-bit number into a 32-bit pointer
;;
;; Input:
;; : de - 16-bit nubmer
;; : hl - 32-bit pointer
;;
;; Output:
;; : (hl) = de
;;
;; Destroyed:
;; : a, hl

	ld (hl), l
	inc hl
	ld (hl), h
	inc hl
	ld (hl), 0
	inc hl
	ld (hl), 0
	ret
.endf ;ld16


.func ld32:
;; Copy a 32-bit number from (hl) to (de)
;;
;; Input:
;; : (hl) - 32-bit number
;; : de - 32-bit pointer
;;
;; Destroyed:
;; : bc, de, hl

	ld bc, 4
	ldir
	ret
.endf ;ld32


.func cp32:
;; Compares two 32-bit numbers
;;
;; Input:
;; : (hl), (de) - 32-bit numbers
;;
;; Output:
;; : c - (hl)<(de)
;; : nc - (hl)>=(de)
;; : z - (hl)=(de)
;; : nz - (hl)!=(de)
;;
;; Destroyed:
;; : a, b, de, hl

;move the pointers to the msb
	ld b, 3
startLoop:
	inc hl
	inc de
	djnz startLoop

	ld b, 4
loop:
	ld a, (de)
	ret nz
	dec hl
	dec de
	djnz loop
	ret
.endf ;cp32


.func clear32:
;; Sets a 32-bit number to 0
;;
;; Input:
;; : (hl) - 32-bit number
;;
;; Output:
;; : (hl) = 0
;;
;; Destroyed:
;; : b, hl

	ld b, 4
loop:
	ld (hl), 0
	inc hl
	djnz loop
	ret
.endf ;clear32
