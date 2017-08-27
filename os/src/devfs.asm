;; Device filesystem
.list

.define devfs_name         0
.define devfs_entryDriver  8
.define devfs_number      10
;.define devfs_attributes  11
.define devfs_data        11


devfs_fsDriver:
	.dw devfs_init
	.dw devfs_open
	.dw devfs_close
	.dw devfs_readdir
	.dw devfs_fstat

.define dev_fileTableDirEntry fileTableData             ;Pointer to entry in devfs
.define dev_fileTableNumber   dev_fileTableDirEntry + 2
.define dev_fileTableData     dev_fileTableNumber + 1

devfs_fileDriver:
	.dw 0x0000 ;devfs_read
	.dw 0x0000 ;devfs_write


.func devfs_init:
;; Adds all permanently attached devices

	;ft240
	ld hl, tty0name
	ld de, ft240_fileDriver
	ld a, 0
	call devfs_addDev

	ld hl, sdaName
	ld de, sd_fileDriver
	ld a, 0
	call devfs_addDev

	ld hl, sda1Name
	ld de, sd_fileDriver
	ld a, 1
	call devfs_addDev
	call clear32
	ld a, 89h
	call ld8

	xor a
	ret


tty0name:
	.asciiz "TTY0"
sdaName:
	.asciiz "SDA"
sda1Name:
	.asciiz "SDA1"
.endf ;devfs_init


.func devfs_addDev:
;; Add a new device entry
;;
;; Input:
;; : (hl) - name
;; : de - driver address
;; : a - number / port
;;
;; Output:
;; : carry - unable to create entry
;; : nc - no error
;; : hl - custom data start

	push af
	push de
	push hl

	;find free entry
	ld a, 0
	ld hl, devfsRoot
	ld de, devfsEntrySize
	ld bc, devfsEntries

findEntryLoop:
	cp (hl)
	jr z, freeEntryFound
	add hl, de
	djnz findEntryLoop

	;no free entry found
	pop hl
	pop hl
	pop hl
	scf
	ret

freeEntryFound:
	;hl = entry

	;copy filename
	pop de ;name
	ex de, hl
	ld bc, 8
	ldir
	ex de, hl

	;register driver address
	pop de ;driver address
	ld (hl), e
	inc hl
	ld (hl), d
	inc hl

	;dev number
	pop af
	ld (hl), a
	inc hl

	or a
	ret
.endf

.func devfs_addExpCard:
;; Add an entry for an expansion card to the devfs and initialise the module.
;; Should eventually also read the eeprom and handle driver loading somehow.
;;
;; Input:
;; : b - expansion slot number
;; : de - device driver (temporary)

	;TODO check if card is inserted; read the eeprom; evt. load driver; needs unio driver

	;calculate port
	;port = $80 + n * 16
	xor a
	cp b
	jr z, portFound
	ld a, 7
	cp b
	jr c, error ;invalid slot number

	ld a, 80h
portLoop:
	add a, 16
	djnz portLoop
portFound:
	
	call devfs_addDev
	jr c, error

error:
	ret
.endf


.func devfs_open:
;; Open a device file
;;
;; Input:
;; : ix - table entry
;; : (de) - absolute path
;;
;; Output:
;; : a - errno

; Errors: 0=no error
;         4=no matching file found

	ld a, (de)
	cp 0x00
	jr nz, notRootDir
	;root directory

	;store file driver
	ld a, devfs_fileDriver & 0xff
	ld (ix + fileTableDriver), a
	ld a, devfs_fileDriver >> 8
	ld (ix + fileTableDriver + 1), a

	;store size
	ld de, devfsEntries * devfsEntrySize
	ld b, ixh
	ld c, iyl
	ld hl, fileTableSize
	add hl, bc
	call ld16

	;set type to directory
	ld a, (ix + fileTableMode)
	or M_DIR
	ld (ix + fileTableMode), a

	;set dirEntry pointer to 0 to indicate root dir
	xor a
	ld (ix + dev_fileTableDirEntry), a
	ld (ix + dev_fileTableDirEntry + 1), a

	ret


notRootDir:
	ld hl, devfsRoot
	push de ;path
	push hl ;file entry
	ld b, 8
	call strncmp
	jr z, fileFound

fileSearchLoop:
	ld de, devfsEntrySize
	pop hl ;file entry
	add hl, de
	pop de ;path
	ld a, (hl)
	cp 0
	jr z, invalidFile
	push de ;path
	push hl ;file entry
	ld b, 8
	call strncmp
	jr nz, fileSearchLoop

fileFound:
	pop iy ;pointer to devfs file entry
	pop de ;path, not needed anymore

	;copy file information
	ld a, (iy + devfs_entryDriver)
	ld (ix + fileTableDriver), a
	ld a, (iy + devfs_entryDriver + 1)
	ld (ix + fileTableDriver + 1), a

	ld a, (iy + devfs_number)
	ld (ix + dev_fileTableNumber), a

	;copy custom data
	ld bc, devfsEntrySize - devfs_data
	ld d, ixh
	ld e, ixl
	ld hl, dev_fileTableData
	add hl, de
	push hl
	ld d, iyh
	ld e, iyl
	;store dirEntry pointer while we have a pointer in a register
	ld (ix + dev_fileTableDirEntry), e
	ld (ix + dev_fileTableDirEntry + 1), d
	ld hl, devfs_data
	add hl, de
	pop de
	ldir

	;store filetype TODO add distincion between char and block devs
	ld a, (ix + fileTableMode)
	or M_CHAR
	ld (ix + fileTableMode), a

	;operation succesful
	xor a
	ret

invalidFile:
	ld a, 4
	ret
.endf ;devfs_open


.func devfs_close:

	ret
.endf ;devfs_close


.func devfs_readdir:
;; Get information about the next file in a directory.
;;
;; Input:
;; : a - dirfd
;; : (de) - stat
;;
;; Output:
;; : a - errno

	push af

	;check if root dir
	ld a, (ix + dev_fileTableDirEntry)
	cp 0x00
	jr nz, error
	ld a, (ix + dev_fileTableDirEntry + 1)
	cp 0x00
	jr nz, error

	ld c, (ix + fileTableOffset)
	ld b, (ix + fileTableOffset + 1)
	ld hl, devfsRoot
	add hl, bc

	xor a
	cp (hl)
	jr z, error ;end of dir

	;seek to next entry
	pop af
	push de
	push hl
	ld de, devfsEntrySize
	ld h, K_SEEK_PCUR
	call k_seek
	pop hl
	pop de

	;hl points to dirEntry
	jr devfs_statFromEntry


error:
	pop af
	ld a, 1
	ret
.endf


.func devfs_fstat:
;; Get information about a file.
;;
;; Input:
;; : ix - file entry addr
;; : (de) - stat
;;
;; Output:
;; : a - errno


	;check if root dir
	ld a, (ix + dev_fileTableDirEntry)
	cp 0x00
	jr nz, notRootDir
	ld a, (ix + dev_fileTableDirEntry + 1)
	cp 0x00
	jr z, rootDir

notRootDir:
	ld b, ixh
	ld c, ixl
	ld hl, dev_fileTableDirEntry
	add hl, bc
	;hl points to dirEntry
	jr devfs_statFromEntry

rootDir:
	xor a
	ld (de), a ;name = null
	ld hl, STAT_ATTRIB
	add hl, de
	;TODO permission of drive
	ld (hl), SP_READ | SP_WRITE | ST_DIR
	;file size is unspecified
	;a = 0
	ret
.endf


.func devfs_statFromEntry:
;; Creates a stat from a directory entry.
;;
;; Input:
;; : (hl) - dir entry
;; : (de) - stat

	;copy name
	push de
	call strcpy
	pop de
	ex de, hl
	;(hl) = stat, (de) = dirEntry
	ld bc, STAT_ATTRIB
	add hl, bc
	;(hl) = stat_attrib
	;TODO store actual attribs
	ld (hl), SP_READ | SP_WRITE | ST_CHAR

	;file size is unspecified

	xor a
	ret
.endf
