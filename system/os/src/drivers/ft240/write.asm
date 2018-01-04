MODULE ft240_write

SECTION rom_code
INCLUDE "drivers/ft240.h"

PUBLIC ft240_write

ft240_write:
;; Write to the USB-connection on the mainboard
;;
;; Input:
;; : ix - file entry addr
;; : (de) - buffer
;; : bc - count
;;
;; Output:
;; : de - count
;; : a - errno
; Errors: 0=no error

	;calculate loop value in bc
	ld a, c
	dec bc
	inc b
	ld c, b
	ld b, a

	ld hl, 0

poll:
	in a, (FT240_STATUS_PORT)
	bit 0, a
	jr nz, poll
	ld a, (de)
	cp '\n'
	call z, newline
	out (FT240_DATA_PORT), a
	inc de
	inc hl
	djnz poll
	dec c
	jr nz, poll
	ex de, hl
	ret

newline:
	ld a, '\r'
	out (FT240_DATA_PORT), a
	ld a, '\n'
	ret
	