* b_time.s
* This contains built-in command 'time'.
*
* Itagaki Fumihiko 22-Dec-90  Create.

.xref copy_wordlist
.xref report_time
.xref DoSimpleCommand_recurse_2

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
		move.l	shell_timer_high(a5),d3
		move.l	shell_timer_low(a5),d2
		tst.w	d0
		bne	cmd_time_recurse

		jmp	report_time			*  0 Ç≈ãAÇÈ

cmd_time_recurse:
		movea.l	a0,a1
		moveq	#1,d1
		jsr	DoSimpleCommand_recurse_2	*** çƒãA ***
		moveq	#0,d0
		rts

.end
