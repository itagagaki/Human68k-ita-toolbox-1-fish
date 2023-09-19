* b_eval.s
* This contains built-in command eval.
*
* Itagaki Fumihiko 28-Nov-90  Create.

.include ../src/fish.h

.xref strmove
.xref alloc_new_argbuf
.xref free_current_argbuf
.xref do_line_substhist
.xref cannot_run_command_because_no_memory

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
		move.w	d0,d3				*  D3.W : ˆø”‚Ì”
		beq	return_0

		moveq	#0,d2
		bsr	alloc_new_argbuf
		beq	cannot_run_command_because_no_memory

		move.l	a0,-(a7)
		subq.w	#1,d3
build_line_loop:
		bsr	strmove
		move.b	#' ',-1(a0)
		dbra	d3,build_line_loop

		clr.b	-1(a0)
		movea.l	(a7)+,a0
		sf	d0
		jsr	do_line_substhist		*!! Ä‹A !!*
		jsr	free_current_argbuf
return_0:
		moveq	#0,d0
		rts

.end
