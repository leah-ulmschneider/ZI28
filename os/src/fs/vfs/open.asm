.list

.func u_open:
	ld hl, u_fdTable
	ld c, fdTableEntries
	call open
	; e -= fdTableEntries
	push af
	ld a, e
	sub fdTableEntries
	ld e, a
	pop af
	ret
.endf

k_open:
;; Open a file / device file
;;
;; Creates a new file table entry and returns the corresponding fd
;;
;; Exactly one of the following flags must be set:
;;
;; * `O_RDONLY` : Open for reading only.
;; * `O_WRONLY` : Open for writing only.
;; * `O_RDWR` : Open for reading and writing.
;;
;; Additionally, zero or more of the following flags may be specified:
;;
;; * `O_APPEND` : Before each write, the file offset is positioned at the
;; end of the file.
;; * `O_DIRECTORY` : Causes open to fail if the specified file is not a
;; directory.
;; * `O_TRUNC` : (Planned) If the file exists and opened for writing, its size gets
;; truncated to 0.
;;
;; Before calling the filesystem routine, the mode field gets populated with
;; the requested access mode. The filesystem routine should return with an
;; error if the required permissions are missing. On success it should bitwise
;; OR the filetype with the mode.
;;
;; Input:
;; : (de) - pathname
;; : a - mode
;;
;; Output:
;; : e - file descriptor
;; : a - errno
;Errors: 0=no error
;        1=maximum allowed files already open
;        2=invalid drive number
;        3=invalid path
;        4=no matching file found
;        5=file too large

	ld hl, k_fdTable
	ld c, 0

.func open:
;; Input:
;; : hl - base address of fd-table
;; : c - base fd
;; : (de) - pathname
;; : a - mode
;;
;; Output:
;; : e - file descriptor
;; : a - errno


;TODO convert path to uppercase
	ld (k_open_mode), a
	ld (k_open_path), de

	ld a, 0xff
	ld b, fdTableEntries
fdSearchLoop:
	cp (hl)
	jr z, fdFound
	inc c
	inc hl
	djnz fdSearchLoop

	;no free fd
	ld a, 0xe0 ;TODO errno
	ret

fdFound:
	ld a, c
	ld (k_open_fd), a

	;search free file table spot
	ld ix, fileTable
	ld b, fileTableEntries
	ld c, 0
	ld de, fileTableEntrySize

tableSearchLoop:
	ld a, (ix + 0)
	cp 00h
	jr z, tableSpotFound
	add ix, de
	inc c
	djnz tableSearchLoop

	;no free spot found, return error
	ld a, 0xf0 ;TODO errno
	ret

tableSpotFound:
	ld a, c
	ld (k_open_fileIndex), a


	ld hl, (k_open_path)
	call realpath

	inc hl
	ld d, h
	ld e, l
	;(de) = drive label

fullPathSplitLoop:
	inc hl
	ld a, (hl)
	cp 0x00
	jr z, rootDir
	cp '/'
	jr nz, fullPathSplitLoop

	xor a
	ld (hl), a ;terminate drive name
	inc hl
rootDir:
	;(hl) = absolute path
	ld (k_open_path), hl


	;(de) = drive label
	ld c, driveTableEntries
	ld hl, driveTable

findDriveLoop:
	push de ;drive label
	push hl ;drive entry

	call strcmp
	jr z, findDriveCmpEnd

findDriveCmpFail:
	pop hl ;drive entry
	ld de, driveTableEntrySize
	add hl, de
	pop de ;drive label

	dec c
	jr nz, findDriveLoop

	;drive not found
	ld a, 0xf3
	ret

findDriveCmpEnd:
	ld a, (de)
	cp '/'
	jr z, driveFound
	cp 0x00
	jr nz, findDriveCmpFail

driveFound:
	pop hl ;drive entry
	pop de ;clear the stack
	;(hl) = drive entry

	;calculate the drive number
	;c = driveTableEntries - driveNumber
	;=> driveNumber = driveTableEntries - c
	ld a, driveTableEntries
	sub c
	ld (k_open_drive), a
	
	ld de, driveTableFsdriver
	add hl, de
	ld e, (hl)
	inc hl
	ld d, (hl)
	ex de, hl ;(hl) = Fsdriver

	and a
	ld de, 0
	sbc hl, de
	jr z, invalidDrive;NULL pointer
	ld de, fs_open
	add hl, de
	ld e, (hl)
	inc hl
	ld d, (hl)
	ex de, hl

	;store requested permissions
	ld a, (k_open_mode)
	ld b, a
	xor a
	bit O_RDONLY_BIT, b
	jr nz, skipWriteFlag
	ld a, M_WRITE
skipWriteFlag:
	bit O_WRONLY_BIT, b
	jr nz, skipReadFlag
	or M_READ
skipReadFlag:
	bit O_APPEND_BIT, b
	jr z, skipAppendFlag
	or M_APPEND
skipAppendFlag:
	ld (ix + fileTableMode), a


	ld a, (k_open_drive)
	ld (ix + fileTableDriveNumber), a
	xor a
	ld (ix + fileTableOffset + 0), a
	ld (ix + fileTableOffset + 1), a
	ld (ix + fileTableOffset + 2), a
	ld (ix + fileTableOffset + 3), a

	push ix
	ld de, return
	push de
	ld de, (k_open_path)

	jp (hl)

return:
	pop ix
	cp 0
	jr nz, error

	ld a, (k_open_mode)
	bit O_DIRECTORY_BIT, a
	jr z, success
	;check if directory
	ld a, (ix + fileTableMode)
	bit M_DIR_BIT, a
	jr z, error ;not a directory

success:
	ld (ix + fileTableRefCount), 1
	ld a, (k_open_fileIndex)
	push af ;file index
	ld a, (k_open_fd)
	push af ;fd
	call getFdAddr
	pop af ;fd
	ld e, a
	pop af ;file index
	ld (hl), a
	xor a
	ret

error:
	;error, clear the file entry
	ld (ix + fileTableMode), 0
	ld a, 1
	ret


invalidDrive:
	ld a, 0xf4
	ret
invalidPath:
	ld a, 0xf5
	ret

.endf