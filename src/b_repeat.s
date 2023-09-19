*  b_repeat.s
*  This contains built-in command 'repeat'.
*
*  Itagaki Fumihiko 14-Oct-90  Create.

.xref atou
.xref strcmp
.xref strfor1
.xref wordlistlen
.xref copy_wordlist
.xref xmalloc
.xref free_current_argbuf
.xref DoSimpleCommand_recurse_2
.xref too_few_args
.xref usage
.xref cannot_because_no_memory
.xref badly_formed_number
.xref too_large_number

.xref current_argbuf

.text

****************************************************************
alloc_new_argbuf:
		move.w	d1,d0
		bsr	wordlistlen
		addq.l	#4,d0
		bsr	xmalloc
		beq	alloc_new_argbuf_fail

		move.l	a1,-(a7)
		movea.l	a0,a1
		movea.l	d0,a0
		move.l	current_argbuf(a5),(a0)
		move.l	a0,current_argbuf(a5)
		addq.l	#4,a0
		moveq	#0,d0
		move.w	d1,d0
		bsr	copy_wordlist
		tst.l	d0
		movea.l	(a7)+,a1
alloc_new_argbuf_return:
		rts

alloc_new_argbuf_fail:
		moveq	#-1,d0
		rts
****************************************************************
*  Name
*       repeat - repeat command
*
*  Synopsis
*       repeat times command
****************************************************************
.xdef cmd_repeat

cmd_repeat:
		move.w	d0,d2
		subq.w	#1,d2
		bls	repeat_too_few_args

		lea	str_oo,a1
		bsr	strcmp
		beq	repeat_oo

		bsr	atou
		bmi	badly_formed_number

		tst.b	(a0)+
		bne	badly_formed_number

		tst.l	d0
		bne	too_large_number

		move.l	d1,d3
		beq	return_0

		sf	d4
		bra	start

repeat_oo:
		bsr	strfor1
		st	d4
start:
		move.w	d2,d1
		bsr	alloc_new_argbuf
		bmi	cannot_repeat
loop:
		movem.l	d0/d3-d4,-(a7)
		moveq	#0,d1
		movea.l	current_argbuf(a5),a1
		addq.l	#4,a1
		jsr	DoSimpleCommand_recurse_2	*** 再帰 ***
		movem.l	(a7)+,d0/d3-d4
		tst.b	d4
		bne	loop

		subq.l	#1,d3
		bne	loop

		jsr	free_current_argbuf
return_0:
		moveq	#0,d0
		rts
****************
repeat_too_few_args:
		bsr	too_few_args
		lea	msg_usage,a0
		bra	usage
****************
cannot_repeat:
		lea	msg_repeat,a0
		bra	cannot_because_no_memory
****************
.data

str_oo:		dc.b	'oo',0
msg_usage:	dc.b	'{ <回数> | oo } <コマンド>',0
msg_repeat:	dc.b	'repeatを実行できません',0

.end
