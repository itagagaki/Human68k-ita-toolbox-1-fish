* b_exit.s
* This contains built-in command 'exit'.
*
* Itagaki Fumihiko 27-Aug-90  Create.

.xref expression
.xref just_set_status
.xref too_many_args

.xref exitflag

.text

****************************************************************
*  Name
*       exit - exit shell
*
*  Synopsis
*       exit [ expression ]
****************************************************************
.xdef cmd_exit

cmd_exit:
		move.w	d0,d7
		moveq	#0,d0
		tst.w	d7
		beq	success_return

		bsr	expression
		bne	cmd_exit_return		* D0 != 0

		tst.w	d7
		bne	too_many_args

		move.l	d1,d0
		bsr	just_set_status
success_return:
		st	exitflag(a5)
		moveq	#0,d0
cmd_exit_return:
		rts

.end
