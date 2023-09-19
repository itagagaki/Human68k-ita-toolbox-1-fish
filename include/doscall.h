	.nlist

DOS	macro	callname
	dc.w	callname
	endm

_EXIT		equ	$ff00
_GETCHAR	equ	$ff01
_PUTCHAR	equ	$ff02
_COMINP		equ	$ff03
_COMOUT		equ	$ff04
_PRNOUT		equ	$ff05
_INPOUT		equ	$ff06
_INKEY		equ	$ff07
_GETC		equ	$ff08
_PRINT		equ	$ff09
_GETS		equ	$ff0a
_KEYSNS		equ	$ff0b
_KFLUSH		equ	$ff0c
_FFLUSH		equ	$ff0d
_CHGDRV		equ	$ff0e
_DRVCTRL	equ	$ff0f
_CONSNS		equ	$ff10
_PRNSNS		equ	$ff11
_CINSNS		equ	$ff12
_COUTSNS	equ	$ff13
_NETWORK_IP	equ	$ff14	*RESERVED
_TRANS_TCP	equ	$ff15	*RESERVED
_SESSION	equ	$ff16	*RESERVED
_FATCHK		equ	$ff17
_HENDSP		equ	$ff18	*RESERVED
_CURDRV		equ	$ff19
_GETSS		equ	$ff1a
_FGETC		equ	$ff1b
_FGETS		equ	$ff1c
_FPUTC		equ	$ff1d
_FPUTS		equ	$ff1e
_ALLCLOSE	equ	$ff1f
_SUPER		equ	$ff20
_FNCKEY		equ	$ff21
_KNJCTRL	equ	$ff22
_CONCTRL	equ	$ff23
_KEYCTRL	equ	$ff24
_INTVCS		equ	$ff25
_PSPSET		equ	$ff26
_GETTIM2	equ	$ff27
_SETTIM2	equ	$ff28
_NAMESTS	equ	$ff29
_GETDATE	equ	$ff2a
_SETDATE	equ	$ff2b
_GETTIME	equ	$ff2c
_SETTIME	equ	$ff2d
_VERIFY		equ	$ff2e
_DUP0		equ	$ff2f
_VERNUM		equ	$ff30
_KEEPPR		equ	$ff31
_GETDPB		equ	$ff32
_BREAKCK	equ	$ff33
_DRVXCHG	equ	$ff34
_INTVCG		equ	$ff35
_DSKFRE		equ	$ff36
_NAMECK		equ	$ff37
*	reserved	$ff38
_MKDIR		equ	$ff39
_RMDIR		equ	$ff3a
_CHDIR		equ	$ff3b
_CREATE		equ	$ff3c
_OPEN		equ	$ff3d
_CLOSE		equ	$ff3e
_READ		equ	$ff3f
_WRITE		equ	$ff40
_DELETE		equ	$ff41
_SEEK		equ	$ff42
_CHMOD		equ	$ff43
_IOCTRL		equ	$ff44
_DUP		equ	$ff45
_DUP2		equ	$ff46
_CURDIR		equ	$ff47
_MALLOC		equ	$ff48
_MFREE		equ	$ff49
_SETBLOCK	equ	$ff4a
_EXEC		equ	$ff4b
_EXIT2		equ	$ff4c
_WAIT		equ	$ff4d
_FILES		equ	$ff4e
_NFILES		equ	$ff4f
_SETPDB		equ	$ff50
_GETPDB		equ	$ff51
_SETENV		equ	$ff52
_GETENV		equ	$ff53
_VERIFYG	equ	$ff54
_COMMON		equ	$ff55
_RENAME		equ	$ff56
_FILEDATE	equ	$ff57
_MALLOC2	equ	$ff58
*	reserved	$ff59
_MAKETMP	equ	$ff5a
_NEWFILE	equ	$ff5b
_LOCK		equ	$ff5c
*	reserved	$ff5d
_NETINF		equ	$ff5e	*RESERVED
_ASSIGN		equ	$ff5f
_S_MALLOC	equ	$ff7d
_S_MFREE	equ	$ff7e
_S_PROCESS	equ	$ff7f
_EXITVC		equ	$fff0
_CTRLVC		equ	$fff1
_ERRJVC		equ	$fff2
_DISKRED	equ	$fff3
_DISKWRT	equ	$fff4
_INDOSFLG	equ	$fff5
_SUPER_JSR	equ	$fff6
_BUS_ERR	equ	$fff7
_OPEN_PR	equ	$fff8
_KILL_PR	equ	$fff9
_GET_PR		equ	$fffa
_SUSPEND	equ	$fffb
_SLEEP_PR	equ	$fffc
_SEND_PR	equ	$fffd
_TIME_PR	equ	$fffe
_CHANGE_PR	equ	$ffff

	.list
