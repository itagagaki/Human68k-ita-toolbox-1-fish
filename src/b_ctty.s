* b_ctty.s
* This contains built-in command 'ctty'.
*
* Itagaki Fumihiko 27-Jan-92  Create.

.include doscall.h

.xref stricmp
.xrer too_few_args
.xref too_many_args
.xref usage

.text

****************************************************************
*  Name
*       ctty - 端末を変更する
*
*  Synopsis
*       ctty tty
*            端末を tty に変更する
****************************************************************
.xdef cmd_ctty

cmd_ctty:
		subq.w	#1,d0
		blo	too_few_args
		bhi	too_many_args

		lea	str_con,a1
		bsr	stricmp
		beq	ctty_con

		lea	str_aux,a1
		bsr	stricmp
		bne	ctty_error
ctty_aux:
		moveq	#3,d1
		moveq	#3,d2
		moveq	#3,d3
		bra	do_ctty

ctty_con:
		moveq	#0,d1
		moveq	#1,d2
		moveq	#2,d3
do_ctty:
		clr.w	-(a7)
		move.w	d1,-(a7)
		DOS	_DUP0
		move.w	#1,-(a7)
		move.w	d2,-(a7)
		DOS	_DUP0
		move.w	#2,-(a7)
		move.w	d3,-(a7)
		DOS	_DUP0
		lea	12(a7),a7
		moveq	#0,d0
		rts

ctty_error:
		lea	msg_usage,a0
		bra	usage

.data

msg_usage:	dc.b	'{ CON | AUX }',0
str_con:	dc.b	'CON',0
str_aux:	dc.b	'AUX',0

.end
