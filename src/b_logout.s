* b_logout.s
* This contains built-in command 'logout'.
*
* Itagaki Fumihiko 13-May-91  Create.

.xref enputs1
.xref logout
.xref too_many_args

.xref i_am_login_shell

.text

****************************************************************
*  Name
*       logout - do logout
*
*  Synopsis
*       logout
****************************************************************
.xdef cmd_logout

cmd_logout:
		tst.w	d0
		bne	too_many_args

		tst.b	i_am_login_shell(a5)
		bne	logout

		lea	msg_not_login_shell,a0
		bra	enputs1
****************************************************************
.data

msg_not_login_shell:	dc.b	'ログイン・シェルではありません',0

.end
