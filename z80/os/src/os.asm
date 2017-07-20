;; OS entry and call table
;ZI-28 OS
;Florian Ulmschneider 2016-2017

;TODO:


.z80


.include "iomap.h"
.include "os_memmap.h"
.include "unistd.h"
.include "syscall.h"
.include "fcntl.h"


; Jump Table -------------------------------------------------

.org memBase

	jp      _coldStart   ;RST 00h
	.db     00h
	jp      00h          ;CALL 04h
	.db     00h
	jp      _putc        ;RST 08h
	.db     00h
	jp      00h          ;CALL 0Ch
	.db     00h
	jp      _getc        ;RST 10h
	.db     00h
	jp      00h          ;CALL 14h
	.db     00h
	jp      00h          ;RST 18h
	.db     00h
	jp      00h          ;CALL 1Ch
	.db     00h
	jp      00h          ;RST 20h
	.db     00h
	jp      00h          ;CALL 24h
	.db     00h
	jp      00h          ;RST 28h
	.db     00h
	jp      00h          ;CALL 2Ch
	.db     00h
	jp      _syscall     ;RST 30h
	.db     00h
	jp      00h          ;CALL 34h
	.db     00h
	jp      _monitor     ;RST 38h

	jp      k_open
	jp      k_close
	jp      k_read
	jp      k_write
	jp      k_seek


;	.resw nmiEntry - $
.org nmiEntry

	.dw ISR_keyboard

.org 0x0100
.include "syscall.asm" ;syscall table must be aligned to 256 bytes


; BIOS-Routines ----------------------------------------------

.include "interrupt.asm"
.include "drivers/ft240.asm"
.include "string.asm"
.include "math.asm"


; Cold start -------------------------------------------------

_coldStart:
	;clear ram TODO other banks
	ld hl, 0x2000
	ld de, 0x2001
	ld bc, 0xdfff
	ld (hl), 0x00
	ldir

	ld sp, sysStack

	;clear the fd tables (set everything to 0xff)
	ld hl, k_fdTable
	ld de, k_fdTable + 1
	ld bc, fdTableEntries * 2 - 1
	ld (hl), 0xff
	ldir

	ld a, AP_KERNEL
	ld (activeProcess), a

	ld de, devfs_fsDriver
	ld hl, devDriveName
	xor a
	call k_mount

	;stdin
	ld de, ttyName
	ld a, 1 << O_RDONLY
	call k_open

	;stdout
	ld de, ttyName
	ld a, 1 << O_WRONLY
	call k_open

	;stderr
	ld a, STDERR_FILENO
	ld b, STDOUT_FILENO
	call k_dup


	call sd_init ;TODO automatic init

	;initialise main drive
	ld de, osDevName ;TODO configurable name in eeprom
	ld a, 1 << O_RDWR
	call k_open
	ld a, e
	ld hl, osDriveName
	ld de, fat_fsDriver
	call k_mount
	ld de, osDriveName
	call k_chmain


	call cli

ttyName:
	.asciiz ":DEV/TTY0"
osDevName:
	.asciiz ":DEV/SDA1"
testFileName:
	.asciiz ":SD/BIN/BASIC.BIN"
devDriveName:
	.asciiz "DEV"
osDriveName:
	.asciiz "OS"



; Monitor ----------------------------------------------------

.include "monitor.asm"

.include "drive.asm"
.include "file.asm"
.include "block.asm"
.include "process.asm"

; Filesystems
.include "fat.asm"
.include "devfs.asm"

; Device drivers
.include "drivers/sd.asm"
.include "drivers/ramdisk.asm"

.include "cli.asm"
