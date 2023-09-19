* b_return.s
* This contains built-in command 'return'.
*
* Itagaki Fumihiko 27-Aug-90  Create.

.xref expression
.xref just_set_status
.xref too_many_args

.xref exitflag

.text

****************************************************************
*  Name
*       return - return from source/function
*
*  Synopsis
*       return [ expression ]
****************************************************************
.xdef cmd_return

cmd_return:
		move.w	d0,d7
		moveq	#0,d0
		tst.w	d7
		beq	success_return

		bsr	expression
		bne	cmd_return_return

		tst.w	d7
		bne	too_many_args

		move.l	d1,d0
		bsr	just_set_status
success_return:
		st	exitflag(a5)
		moveq	#0,d0
cmd_return_return:
		rts

.end
