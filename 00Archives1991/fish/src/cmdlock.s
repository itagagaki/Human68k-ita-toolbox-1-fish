* cmdlock.s
* This contains built-in command 'lock'.
*
* Itagaki Fumihiko 28-Dec-90  Create.

.include doscall.h
.include chrcode.h

.text

****************************************************************
*  Name
*       lock - lock terminal
*
*  Synopsis
*       lock
****************************************************************
.xdef cmd_lock

key = -64
buffer = key-64

cmd_lock:
		tst.w	d0
		bne	too_many_args

		link	a6,#buffer
		lea	msg_enter_key(pc),a1
		lea	key(a6),a0
		move.l	#64,d0
		bsr	getpass
		lea	msg_again(pc),a1
		lea	buffer(a6),a0
		move.l	#64,d0
		bsr	getpass
		lea	key(a6),a1
		bsr	strcmp
		bne	diff

		move.b	#1,locking
loop:
		lea	msg_key(pc),a1
		lea	buffer(a6),a0
		move.l	#64,d0
		bsr	getpass
		lea	key(a6),a1
		bsr	strcmp
		bne	loop

		bsr	put_newline
		clr.b	locking
		moveq	#0,d0
return:
		unlk	a6
		rts

diff:
		lea	msg_keys_are_different(pc),a0
		bsr	enputs1
		bra	return
****************************************************************
getpass:
		movem.l	d1/a0,-(a7)
		move.l	d0,d1
		exg	a0,a1
		bsr	puts
		exg	a0,a1
getpass_loop:
		subq.l	#1,d1
		beq	getpass_done

		DOS	_GETC
		tst.l	d0
		bmi	getpass_done

		cmp.b	#CR,d0
		beq	getpass_done

		move.b	d0,(a0)+
		bra	getpass_loop

getpass_done:
		clr.b	(a0)
		movem.l	(a7)+,d1/a0
		rts
****************************************************************
.data

msg_enter_key:			dc.b	'キーを入力してください:',0
msg_again:			dc.b	CR,LF,'もう一度:',0
msg_keys_are_different:		dc.b	CR,LF,'キーが違います',0
msg_key:			dc.b	CR,LF,'キー:',0

.end
