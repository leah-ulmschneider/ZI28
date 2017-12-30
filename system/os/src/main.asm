;; OS entry and call table
;ZI-28 OS
;Florian Ulmschneider 2016-2017

;TODO:


.z80

.define __NAKEN_ASM


.include "iomap.h"
.include "os_memmap.h"
.include "sys/os.h"
.include "errno.h"
.include "fs/vfs/vfs.h"
.include "fs/fatfs/fatfs.h"
.include "fs/devfs/devfs.h"


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
	jp      _strerror    ;RST 28h
	.db     00h
	jp      00h          ;CALL 2Ch
	.db     00h
	jp      _syscall     ;RST 30h
	.db     00h
	jp      00h          ;CALL 34h
	.db     00h
	jp      _monitor     ;RST 38h


;	.resw nmiEntry - $
.org nmiEntry

	.dw ISR_keyboard

.org 0x0100
.include "syscall.asm" ;syscall table must be aligned to 256 bytes


; BIOS-Routines ----------------------------------------------

.include "interrupt.asm"
.include "string.asm"
.include "math.asm"


; Cold start -------------------------------------------------

_coldStart:
	;clear ram TODO other banks
	ld hl, 0x4000
	ld de, 0x4001
	ld bc, 0xbfff
	ld (hl), 0x00
	ldir

	ld sp, sysStack

	;clear the fd tables (set everything to 0xff)
	ld hl, k_fdTable
	ld de, k_fdTable + 1
	ld bc, fdTableEntries * 2 - 1
	ld (hl), 0xff
	ldir

	call dummyRoot
	ld hl, devfsMountPoint
	ld d, FS_DEV
	ld e, 0xff
	call k_mount

	;stdin
	ld de, ttyName
	ld a, O_RDONLY
	call k_open

	;stdout
	ld de, ttyName
	ld a, O_WRONLY
	call k_open

	;stderr
	ld a, STDERR_FILENO
	ld b, STDOUT_FILENO
	call k_dup


	call sd_init ;TODO automatic init

	;initialise main drive
	ld de, osDevName ;TODO configurable name in eeprom
	ld a, FS_FAT
	call mountRoot


	ld hl, homeDir
	call k_chdir

	call b_cls
	jp cli

ttyName:
	.asciiz "/DEV/TTY0"
osDevName:
	.asciiz "/DEV/SDA1"
devfsMountPoint:
	.asciiz "/DEV"
homeDir:
	.asciiz "/HOME"



; Monitor ----------------------------------------------------

.include "monitor.asm"

.include "error.asm"
.include "drive.asm"
.include "block.asm"
.include "process.asm"

; Filesystems
.include "path.asm"
.include "fs/vfs/vfs.asm"
.include "fs/fatfs/fatfs.asm"
.include "fs/devfs/devfs.asm"

; Device drivers
.include "drivers/sd.asm"
.include "drivers/ft240.asm"

.include "shell/cli.asm"
.include "gitversion.asm"
