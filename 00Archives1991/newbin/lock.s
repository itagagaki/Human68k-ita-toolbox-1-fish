* lock.s
*
* Itagaki Fumihiko 28-Dec-90  Create.
****************************************************************
*  Name
*       lock - lock terminal
*
*  Synopsis
*       lock
****************************************************************

.include doscall.h
.include chrcode.h

MAXKEYLEN	EQU	64	* unsigned WORD
STACKSIZE	EQU	512

.text
****************************************************************
start:
		lea	stack(pc),a7
		lea	msg_enter_key(pc),a1
		lea	key(pc),a0
		bsr	getpass
		lea	length(pc),a0
		move.w	d1,(a0)
		lea	msg_again(pc),a1
		lea	buffer(pc),a0
		bsr	getpass
		lea	key(pc),a1
		bsr	compare
		bne	diff

		pea	lock(pc)
		move.w	#_CTRLVC,-(a7)
		DOS	_INTVCS
		addq.l	#6,a7

		pea	lock(pc)
		move.w	#_ERRJVC,-(a7)
		DOS	_INTVCS
		addq.l	#6,a7

		lea	msg_locked(pc),a1
		bsr	puts
lock:
		lea	stack(pc),a7
		lea	msg_key(pc),a1
		lea	buffer(pc),a0
		bsr	getpass
		lea	key(pc),a1
		bsr	compare
		bne	lock

		clr.w	-(a7)
		DOS	_EXIT2

diff:
		lea	msg_keys_are_different(pc),a1
		bsr	puts
		move.w	#1,-(a7)
		DOS	_EXIT2
****************************************************************
compare:
		lea	length(pc),a2
		cmp.w	(a2),d1
		bne	compare_done

		tst.w	d1
		beq	compare_done
compare_loop:
		cmpm.b	(a0)+,(a1)+
		bne	compare_done

		subq.w	#1,d1
		bne	compare_loop
compare_done:
		rts
****************************************************************
getpass:
		move.l	a0,-(a7)
		bsr	puts
		moveq	#0,d1
getpass_loop:
		cmp.w	#MAXKEYLEN,d1
		beq	getpass_done

		DOS	_GETC
		tst.l	d0
		bmi	getpass_done

		cmp.b	#CR,d0
		beq	getpass_done

		move.b	d0,(a0)+
		addq.w	#1,d1
		bra	getpass_loop

getpass_done:
		movea.l	(a7)+,a0
		lea	str_newline(pc),a1
puts:
		move.l	a1,-(a7)
		DOS	_PRINT
		movea.l	(a7)+,a1
		rts
****************************************************************
.data

msg_enter_key:		dc.b	'キーを入力してください:',0
msg_again:		dc.b	'もう一度:',0
msg_locked:		dc.b	'ロックしました',CR,LF,0
msg_key:		dc.b	'キー:',0
msg_keys_are_different:	dc.b	'キーが違います'
str_newline:		dc.b	CR,LF,0
****************************************************************
.bss

.even
length:		ds.w	1
key:		ds.b	MAXKEYLEN
buffer:		ds.b	MAXKEYLEN

		ds.b	STACKSIZE
stack:
****************************************************************

.end start
