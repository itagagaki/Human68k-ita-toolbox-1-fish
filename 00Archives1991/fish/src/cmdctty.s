*****************************************************************
*								*
*	change tty command					*
*								*
*	CTTY [device name]					*
*								*
*	device name list					*
*		AUX	auxiliary device (RS-232C)		*
*		CON	console device				*
*								*
*****************************************************************

.include doscall.h
.include ../src/fish.h

.xref too_few_args
.xref too_many_args
.xref usage
.xref stricmp

.text

*****************************************************************
*								*
*	ctty command entry					*
*								*
*****************************************************************
.xdef	cmd_ctty

cmd_ctty:
		cmp.w	#1,d0
		blo	too_few_args
		bhi	too_many_args

		lea	word_aux,a1
		bsr	stricmp
		beq	ctty_aux

		lea	word_con,a1
		bsr	stricmp
		beq	ctty_con

		lea	msg_usage,a0
		bra	usage

ctty_con:
		moveq	#0,d1
		moveq	#1,d2
		moveq	#2,d3
		bra	do_ctty
ctty_aux:
		moveq	#3,d1
		move.w	d1,d2
		move.w	d1,d3
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

.data

word_aux:	dc.b	'aux',0
word_con:	dc.b	'con',0

msg_usage:	dc.b	'{ AUX | CON }',0

.end
