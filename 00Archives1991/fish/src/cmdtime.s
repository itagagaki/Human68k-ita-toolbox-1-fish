* cmdtime.s
* This contains built-in command 'time'.
*
* Itagaki Fumihiko 22-Dec-90  Create.

.xref copy_wordlist
.xref getitimer
.xref puts
.xref count_time
.xref report_time
.xref DoSimpleCommand
.xref msg_total_time
.xref shell_timer_low
.xref shell_timer_high
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

		move.w	d0,argc
		movea.l	a0,a1
		lea	simple_args,a0
		bsr	copy_wordlist
		moveq	#1,d1
		bsr	DoSimpleCommand		*** çƒãA ***
cmd_time_done:
		moveq	#0,d0
		rts

report_shell_time:
		bsr	getitimer
		move.l	shell_timer_low,d2
		move.l	shell_timer_high,d3
		bsr	count_time
		lea	msg_total_time(pc),a0
		lea	puts(pc),a1
		bsr	report_time
		bra	cmd_time_done

.end
