;****************************
;Basic Card Operating System
;Florian Ulmschneider 2016

.z80
.include "biosCalls.h"
.include "bcosCalls.h"

.define sdBuffer 4200h

	org 5000h
	jp _bcosStart
	;TODO check if c is valid
	push af
	push hl
	ld hl, bcosVectTable
	ld b, 0
	add hl, bc
	add hl, bc

	ld a, (hl)
	.dw 6fddh ;ld ixl, a
	inc hl
	ld a, (hl)
	.dw 67ddh ;ld ixh, a
	pop hl
	pop af
	jp (ix)

bcosVectTable:
	.dw _bcosStart
	.dw _openFile
	.dw _closeFile
	.dw _readFile
;	.dw _writeFile
;	.dw _chdir
;	.dw _setDrive
	.dw _setProcTable


_bcosStart:

	;TODO setup stack and interrupts
	ld sp, 8000h

	call vfs_init
	call fat_init
	ld de, shellPath
	call _openFile
	ld a, e
	ld de, 6000h
	ld hl, 0ffffh
	call _readFile

	ld de, 6000h
	call _setProcTable
	call 6000h
	jp 0
	
shellPath:
	.asciiz "/SYS/CLI.BIN"

.include "drivers.asm"
.include "vfs.asm"
.include "fat.asm"
.include "file.asm"
.include "process.asm"
