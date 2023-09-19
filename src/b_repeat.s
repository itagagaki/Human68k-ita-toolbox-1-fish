*  b_repeat.s
*  This contains built-in command 'repeat'.
*
*  Itagaki Fumihiko 14-Oct-90  Create.

.xref atou
.xref wordlistlen
.xref copy_wordlist
.xref xmalloc
.xref free_current_argbuf
.xref DoSimpleCommand
.xref too_few_args
.xref perror_command_name
.xref pre_perror
.xref enputs1
.xref usage
.xref cannot_because_no_memory
.xref msg_badly_formed_number
.xref msg_too_large_number

.xref argc
.xref simple_args
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

		movea.l	a0,a2
		lea	msg_badly_formed_number,a1
		bsr	atou
		bmi	bad_times

		tst.b	(a0)+
		bne	bad_times

		lea	msg_too_large_number,a1
		tst.l	d0
		bne	bad_times

		move.l	d1,d3
		beq	return_0

		move.w	d2,d1
		bsr	alloc_new_argbuf
		bmi	cannot_repeat
loop:
		movem.l	d0/d3,-(a7)
		move.w	d0,argc(a5)
		movea.l	current_argbuf(a5),a1
		addq.l	#4,a1
		lea	simple_args(a5),a0
		bsr	copy_wordlist
		sf	d1
		st	d2
		bsr	DoSimpleCommand			*** 再帰 ***
		movem.l	(a7)+,d0/d3
		subq.l	#1,d3
		bne	loop

		jsr	free_current_argbuf
return_0:
		moveq	#0,d0
		rts
****************
bad_times:
		bsr	perror_command_name
		movea.l	a2,a0
		bsr	pre_perror
		movea.l	a1,a0
		bra	enputs1
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

msg_usage:		dc.b	'<回数> <コマンド>',0
msg_repeat:		dc.b	'repeatを実行できません',0

.end
