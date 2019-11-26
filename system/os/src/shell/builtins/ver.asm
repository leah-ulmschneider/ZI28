#code ROM

b_ver:
#local
	ld a, (argc)
	cp 1
	jr nz, invalidCall

	ld hl, version
	call print
	ld a, 0x0a
	jp RST_putc

invalidCall:
	ret
#endlocal
