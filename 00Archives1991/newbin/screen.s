*****************************************************************
*								*
*	screen set command					*
*								*
*	SCREEN <width> <graphicmode> <displaymode>		*
*								*
*****************************************************************

.include doscall.h
.include chrcode.h

.text

cmd_screen:
		clr.w	d2
		move.b	(a2)+,d2
		bsr	skip_space
		beq	initialize

		moveq	#1,d1
		bsr	getarg1
		move.w	d0,d3
		moveq	#3,d1
		bsr	getarg1
		move.w	d0,d4
		moveq	#3,d1
		bsr	getarg2
		bne	error

		move.w	d0,d5
		and.w	d3,d0
		and.w	d4,d0
		not.w	d0				* cmp.l #-1,d0 の代わり
		beq	screen_end			* すべてが -1 （無指定）
********************************
		moveq	#1,d1				* 再設定フラグ を ON にしておく
		cmp.w	#-1,d3
		beq	get_current			* width は無指定

		cmp.w	#-1,d4
		beq	get_current			* graphicmode は無指定
		*
		*  width と graphicmode の両方が指定有り
		*
		move.w	d4,d2
		tst.w	d3
		beq	change_graphicmode_on_width_0

		bra	change_graphicmode_on_width_1
****************
get_current:
		*
		*  width と graphicmode の少なくともどちらかは無指定
		*
		move.w	#-1,-(a7)
		move.w	#16,-(a7)
		DOS	_CONCTRL
		addq.l	#4,a7
		move.w	d0,d2				* 現在のモードを D2 に
		cmp.w	#-1,d3
		bne	width_specified			* width は指定有り

		cmp.w	#-1,d4
		bne	graphicmode_specified		* graphicmode は指定有り
		*
		* width も graphicmode も変更しない
		*
		clr.w	d1				* 再設定フラグ OFF
		bra	width_and_graphicmode_ok
****************
graphicmode_specified:
		*
		* width を変えずに graphicmode を指定値に変更する
		*
		cmp.w	#2,d2
		blo	change_graphicmode_on_width_0

		move.w	d4,d2				* 現在の width は 1 であるから
		bra	change_graphicmode_on_width_1	* モードは 2 + graphicmode とする

change_graphicmode_on_width_0:
		cmp.w	#2,d4				* 現在の width は 0 であるから
		bhs	error				* 2 以上の graphicmode はエラー

		move.w	d4,d2
		bra	width_and_graphicmode_ok	* モードは graphicmode とする
****************
width_specified:
		*
		*  graphicmode を変えずに width を指定値に変更
		*
		tst.w	d3
		beq	change_width_to_0

change_width_to_1:
		*
		* graphicmode を変えずに width を 1 に変更
		*
		cmp.w	#2,d2				* 現在のモードが 2 以上ならば
		bhs	width_and_graphicmode_ok	* そのままで OK

change_graphicmode_on_width_1:
		add.w	#2,d2				* モードに 2 を加える
		bra	width_and_graphicmode_ok

change_width_to_0:
		*
		* graphicmode を変えずに width を 0 に変更
		*
		cmp.w	#2,d2				* 現在のモードが 0 か 1 ならば
		blo	width_and_graphicmode_ok	* そのままで OK

		sub.w	#2,d2				* 2 ならば 0 に、3 ならば 1 に、
		cmp.w	#2,d2
		blo	width_and_graphicmode_ok

		moveq	#1,d2				* 4 以上ならば 1 にする
****************
width_and_graphicmode_ok:
		cmp.w	#-1,d5
		beq	all_fixed

		tst.w	d2
		beq	check_graphic

		cmp.w	#2,d2
		bne	all_fixed
check_graphic:
		btst	#0,d5			* モードが 0 または 2 である場合、
		bne	error			* displaymode に 1 または 3 を指定することはできない
all_fixed:
		tst.w	d1
		beq	change_displaymode
change_mode:
		move.w	d2,-(a7)
		move.w	#16,-(a7)
		DOS	_CONCTRL
		addq.l	#4,a7
change_displaymode:
		cmp.w	#-1,d5
		beq	screen_end

		move.l	#$93,d0
		move.w	#$ffff,d1
		trap	#15
		and.w	#$ffa0,d0
		bset	#5,d0
		btst	#0,d5
		beq	change_displaymode_1

		or.w	#$1f,d0
change_displaymode_1:
		btst	#1,d5
		beq	change_displaymode_2

		bset	#6,d0
change_displaymode_2:
		move.w	d0,d1
		move.l	#$93,d0
		trap	#15
screen_end:
		clr.w	-(a7)
		DOS	_EXIT2
********************************
initialize:
		clr.w	d2
		clr.w	d5
		bra	change_mode
********************************
error:
		move.l	#22,-(a7)	* length
		pea	msg_bad_arg(pc)
		move.w	#2,-(a7)
		DOS	_WRITE
		move.w	#1,(a7)
		DOS	_EXIT2
****************************************************************
getarg1:
		move.w	#-1,d0
		tst.w	d2
		beq	getarg_done

		cmpi.b	#',',(a2)
		beq	noarg1

		bsr	getarg2
		beq	getarg_done

		cmpi.b	#',',(a2)
		bne	getarg_done
noarg1:
		addq.l	#1,a2
		subq.w	#1,d2
		bra	skip_space
********************************
getarg2:
		move.w	#-1,d0
		tst.w	d2
		beq	getarg_done

		moveq	#0,d0
		move.b	(a2)+,d0
		sub.b	#'0',d0
		blo	error

		cmp.w	d1,d0
		bhi	error

		subq.w	#1,d2
		beq	getarg_done

		cmpi.b	#'0',(a2)
		blo	getarg_ok

		cmpi.b	#'9',(a2)
		bls	error
getarg_ok:
********************************
skip_space:
		tst.w	d2
		beq	skip_space_return

		cmpi.b	#' ',(a2)
		beq	skip_space_continue

		cmp.b	#HT,(a2)
		beq	skip_space_continue

		cmpi.b	#CR,(a2)
		beq	skip_space_continue

		cmpi.b	#LF,(a2)
		beq	skip_space_continue

		cmpi.b	#VT,(a2)
		bne	skip_space_return
skip_space_continue:
		addq.l	#1,a2
		subq.w	#1,d2
		bne	skip_space
skip_space_return:
getarg_done:
		rts
****************************************************************

.data

msg_bad_arg:	dc.b	'パラメ－タが無効です',CR,LF

.end cmd_screen
