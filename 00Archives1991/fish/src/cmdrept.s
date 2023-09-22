* cmdrept.s
* This contains built-in command 'repeat'.
*
* Itagaki Fumihiko 14-Oct-90  Create.

.xref atou
.xref wordlistlen
.xref copy_wordlist
.xref DoSimpleCommand0
.xref too_few_args
.xref bad_arg
.xref usage
.xref argc
.xref simple_args

.text

****************************************************************
*  Name
*       repeat - repeat command
*
*  Synopsis
*       repeat times command
****************************************************************
.xdef cmd_repeat

cmd_repeat:
		cmp.w	#2,d0
		blo	repeat_too_few_args

		move.w	d0,d2
		bsr	atou
		bmi	repeat_bad_arg

		tst.b	(a0)+
		bne	repeat_bad_arg

		subq.w	#1,d2
		move.w	d2,d0
		bsr	wordlistlen
		addq.l	#1,d0
		bclr	#0,d0
		movea.l	a7,a2
		suba.l	d0,a7
		movea.l	a0,a1
		movea.l	a7,a0
		move.w	d2,d0
		bsr	copy_wordlist
		movea.l	a7,a1
		bra	continue

loop:
		movem.l	d0-d1/a1-a2,-(a7)
		move.w	d0,argc
		lea	simple_args,a0
		bsr	copy_wordlist
		bsr	DoSimpleCommand0	*** 再帰 ***
		movem.l	(a7)+,d0-d1/a1-a2
continue:
		dbra	d1,loop

		movea.l	a2,a7
		moveq	#0,d0
		rts
****************
repeat_too_few_args:
		bsr	too_few_args
		bra	cmd_repeat_usage

repeat_bad_arg:
		bsr	bad_arg
cmd_repeat_usage:
		lea	msg_usage(pc),a0
		bra	usage
****************
.data

msg_usage:	dc.b	'<回数> <コマンド>',0

.end
