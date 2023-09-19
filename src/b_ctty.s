* b_ctty.s
* This contains built-in command 'ctty'.
*
* Itagaki Fumihiko 27-Jan-92  Create.

		.xdef	cmd_ctty
		.xref	g_eprint,g_stolower,g_strcpy,g_strcmp
		.xref	msg_aux,msg_con,msg_bad_arg,msg_dev_name
		.xref	argc,args
dev_name	=	-280

.text

****************************************************************
*  Name
*       ctty - 端末を変更する
*
*  Synopsis
*       ctty tty
*            端末を tty に変更する
****************************************************************
.xdef cmd_ctty

cmd_ctty:
		link	a6,#dev_name
		cmp.w	#1,d0
		blo	too_few_args
		bhi	too_many_args

		lea	args,a1
		lea	dev_name(a6),a0
		bsr	strcpy
		bsr	stolower
		lea	msg_con,a1
		bsr	strcmp
		beq	ctty_con

		lea	msg_aux,a1
		bsr	strcmp
		bne	ctty_error
ctty_aux:
		moveq	#3,d1
		moveq	#3,d2
		move.w	#3,d3
		bra	do_ctty

ctty_con:
		move.w	#0,d1
		move.w	#1,d2
		move.w	#2,d3
do_ctty:
		move.w	#0,-(a7)
		move.w	d1,-(a7)
		DOS	_DUP0
		move.w	#1,-(a7)
		move.w	d2,-(a7)
		DOS	_DUP0
		move.w	#2,-(a7)
		move.w	d3,-(a7)
		DOS	_DUP0
		lea	12(a7),a7
		moveq	#0,d0
ctty_return:
		unlk	a6
		rts

ctty_error:
		lea	msg_dev_name,a0
		bsr	enputs1
		bra	ctty_return

.end
