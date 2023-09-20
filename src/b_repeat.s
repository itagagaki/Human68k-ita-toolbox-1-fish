*  b_repeat.s
*  This contains built-in command 'repeat'.
*
*  Itagaki Fumihiko 14-Oct-90  Create.

.xref atou
.xref strcmp
.xref memmovi
.xref strfor1
.xref wordlistlen
.xref xmalloc
.xref free_current_argbuf
.xref DoSimpleCommand_recurse_2
.xref too_few_args
.xref usage
.xref cannot_run_command_because_no_memory
.xref badly_formed_number
.xref too_large_number

.xref current_argbuf

.text

****************************************************************
.xdef alloc_new_argbuf

alloc_new_argbuf:
		movea.l	a0,a1
		bsr	wordlistlen
		move.l	d0,d1
		addq.l	#4,d0
		add.l	d2,d0
		bsr	xmalloc
		beq	alloc_new_argbuf_return

		movea.l	d0,a0
		move.l	current_argbuf(a5),(a0)
		move.l	a0,current_argbuf(a5)
		addq.l	#4,a0
alloc_new_argbuf_return:
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
		move.w	d0,d3
		subq.w	#1,d3
		bls	repeat_too_few_args

		lea	str_oo,a1
		jsr	strcmp
		beq	repeat_oo

		jsr	atou
		bmi	badly_formed_number

		tst.b	(a0)+
		bne	badly_formed_number

		tst.l	d0
		bne	too_large_number

		move.l	d1,d4
		beq	return_0

		sf	d5
		bra	start

repeat_oo:
		jsr	strfor1
		st	d5
start:
		move.w	d3,d0
		moveq	#0,d2
		bsr	alloc_new_argbuf
		beq	cannot_run_command_because_no_memory

		move.l	a0,-(a7)
		move.l	d1,d0
		jsr	memmovi
		movea.l	(a7)+,a1
		move.w	d3,d0
loop:
		movem.l	d0/d4-d5/a1,-(a7)
		moveq	#0,d1
		jsr	DoSimpleCommand_recurse_2	*** 再帰 ***
		movem.l	(a7)+,d0/d4-d5/a1
		tst.b	d5
		bne	loop

		subq.l	#1,d4
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
.data

str_oo:		dc.b	'oo',0
msg_usage:	dc.b	'{<回数>|oo} <コマンド名> [<引数リスト>]',0

.end
