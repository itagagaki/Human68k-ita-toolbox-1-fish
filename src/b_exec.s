* b_exec.s
* This contains built-in command 'exec'.
*
* Itagaki Fumihiko 13-Jun-92  Create.

.xref fclosexp
.xref too_many_args

.xref save_stdin
.xref save_stdout
.xref save_stderr
.xref push_stdin
.xref push_stdout
.xref push_stderr
.xref undup_input
.xref undup_output

.text

push_io:
		tst.l	(a1)
		bpl	fclosexp

		move.l	(a0),(a1)
		move.l	#-1,(a0)
		rts
****************************************************************
*  Name
*       exec - execute without fork
*
*  Synopsis
*       exec
****************************************************************
.xdef cmd_exec

cmd_exec:
		tst.w	d0
		bne	too_many_args

		lea	undup_input(a5),a0
		bsr	fclosexp

		lea	undup_output(a5),a0
		bsr	fclosexp

		lea	save_stdin(a5),a0
		lea	push_stdin(a5),a1
		bsr	push_io

		lea	save_stdout(a5),a0
		lea	push_stdout(a5),a1
		bsr	push_io

		lea	save_stderr(a5),a0
		lea	push_stderr(a5),a1
		bsr	push_io

		moveq	#0,d0
		rts

.end
