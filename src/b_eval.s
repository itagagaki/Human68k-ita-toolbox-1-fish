* b_eval.s
* This contains built-in command eval.
*
* Itagaki Fumihiko 28-Nov-90  Create.

.include ../src/fish.h

.xref strmove
.xref wordlistlen
.xref xmalloc
.xref free_current_argbuf
.xref do_line_substhist
.xref cannot_because_no_memory

.xref current_argbuf

.text

****************************************************************
*  Name
*       eval - execute argument on current shell
*
*  Synopsis
*       eval arg ...
****************************************************************
.xdef cmd_eval

cmd_eval:
		move.w	d0,d1			* D2.W : ˆø”‚Ì”
		beq	return_0

		bsr	wordlistlen
		addq.l	#4,d0
		bsr	xmalloc
		beq	cannot_eval

		movea.l	a0,a1
		movea.l	d0,a0
		move.l	current_argbuf(a5),(a0)
		move.l	a0,current_argbuf(a5)
		addq.l	#4,a0
		movea.l	a0,a2
		subq.w	#1,d1
build_line_loop:
		bsr	strmove
		move.b	#' ',-1(a0)
		dbra	d1,build_line_loop

		clr.b	-1(a0)
		movea.l	a2,a0
		sf	d0
		bsr	do_line_substhist		*!! Ä‹A !!*
		bsr	free_current_argbuf
return_0:
		moveq	#0,d0
		rts

cannot_eval:
		lea	msg_eval,a0
		bra	cannot_because_no_memory
****************************************************************
.data

msg_eval:	dc.b	'eval‚ğÀs‚Å‚«‚Ü‚¹‚ñ',0

.end
