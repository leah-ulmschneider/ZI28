.list

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