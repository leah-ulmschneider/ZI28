#code ROM

u_exit:
;; Terminate the current process and return control to the parent.
;;
;; Input:
;; : a - exit status

;needs to return the following for fork:
; a = 1
; e - exit code of terminating process

;TODO what to do if trying to exit pid 1?
; - reboot the system
; - display reboot prompt
; - drop to kernel shell
; - halt the system / panic

	ld (exit_returnCode), a

;restore sp
	ld sp, (kernel_stackSave)

;TODO close all fds

	ld a, 0x08
	out (BANKSEL_PORT), a

	ld a, (exit_returnCode)
	ld e, a
	xor a
	ret

#data RAM
exit_returnCode:
	DEFB 0
