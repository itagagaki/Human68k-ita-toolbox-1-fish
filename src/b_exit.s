* b_exit.s
* This contains built-in command 'exit'.
*
* Itagaki Fumihiko 03-Nov-91  Create.

.xref exit_shell_status
.xref exit_shell_d0
.xref expression
.xref too_many_args

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
		bne	exit_expression

		jmp	exit_shell_status

exit_expression:
		bsr	expression
		bne	cmd_exit_return		* D0 != 0

		tst.w	d7
		bne	too_many_args

		move.l	d1,d0
		jmp	exit_shell_d0

cmd_exit_return:
		rts

.end
