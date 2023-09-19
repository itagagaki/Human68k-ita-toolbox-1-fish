* b_time.s
* This contains built-in command 'time'.
*
* Itagaki Fumihiko 22-Dec-90  Create.

.xref copy_wordlist
.xref getitimer
.xref count_time
.xref report_time
.xref DoSimpleCommand

.xref shell_timer_high
.xref shell_timer_low
.xref argc
.xref simple_args

.text

****************************************************************
*  Name
*       time - report timer
*
*  Synopsis
*       time time [command]
****************************************************************
.xdef cmd_time

cmd_time:
		tst.w	d0
		beq	report_shell_time

		move.w	d0,argc(a5)
		movea.l	a0,a1
		lea	simple_args(a5),a0
		bsr	copy_wordlist
		st	d1
		st	d2
		bsr	DoSimpleCommand			*** çƒãA ***
cmd_time_done:
		moveq	#0,d0
		rts

report_shell_time:
		bsr	getitimer
		move.l	shell_timer_high(a5),d3
		move.l	shell_timer_low(a5),d2
		bsr	count_time
		suba.l	a0,a0
		bsr	report_time
		bra	cmd_time_done

.end
