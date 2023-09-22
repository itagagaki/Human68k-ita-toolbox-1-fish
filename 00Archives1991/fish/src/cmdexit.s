* cmdexit.s
* This contains built-in command 'exit'.
*
* Itagaki Fumihiko 27-Aug-90  Create.

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
		tst.l	rootdata
		bne	exit_ok
.if 0
		tst.b	i_am_login_shell
		beq	exit_ok

		lea	msg_cannot(pc),a0
		bra	enputs1
.endif
exit_ok:
		swap	d0
		clr.w	d0
		swap	d0
		move.w	d0,d7
		beq	success_return

		bsr	expression2
		bne	error_return

		move.l	d1,d0
success_return:
		move.b	#1,exitflag
		rts

error_return:
		moveq	#1,d0
		rts
****************************************************************
.data
.if 0
msg_cannot:	dc.b	'èIóπÇÕ logout',0
.endif
.end
