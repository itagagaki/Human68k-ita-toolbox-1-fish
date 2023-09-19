* b_history.s
* This contains built-in command 'history'.
*
* Itagaki Fumihiko 23-Dec-90  Create.
* Itagaki Fumihiko 19-Aug-91  時刻表示

.include ../src/history.h

.xref atou
.xref utoa
.xref strfor1
.xref strcmp
.xref putc
.xref puts
.xref cputs
.xref enputs1
.xref printu
.xref put_space
.xref put_tab
.xref put_newline
.xref svartol
.xref badly_formed_number
.xref too_many_args
.xref bad_arg
.xref usage
.xref word_history

.xref history_top
.xref history_bot
.xref current_eventno

.text

****************************************************************
*  Name
*       history - print history list
*
*  Synopsis
*       history [ -rht ] [ <イベント数> ]
*
*       -r   逆順に出力する
*       -h   イベント番号や時刻無しで出力する
*       -t   時刻無しで出力する
*
*       history -x <開始番号>[-<終了番号>]
****************************************************************
.xdef cmd_history
.xdef do_print_history

cmd_history:
		move.w	d0,d1
		beq	history_normal

		lea	option_x,a1
		bsr	strcmp
		bne	history_normal

		subq.w	#2,d1
		bhi	b_too_many_args

		bsr	strfor1
		bsr	atou
		bmi	badly_formed_number

		move.l	d0,d3
		move.l	d1,d2
		tst.b	(a0)
		beq	parse_range_done

		cmpi.b	#'-',(a0)+
		bne	b_bad_arg

		bsr	atou
		tst.b	(a0)
		bne	badly_formed_number
parse_range_done:
		tst.l	d0
		bmi	badly_formed_number

		or.l	d3,d0
		bne	b_bad_arg

		moveq	#3,d6				*  イベント番号や時刻は出力しない
		movea.l	history_top(a5),a0
output_region_loop:
		cmpa.l	#0,a0
		beq	history_done

		cmp.l	HIST_EVENTNO(a0),d2
		bhi	output_region_continue

		cmp.l	HIST_EVENTNO(a0),d1
		blo	output_region_continue

		bsr	prhist_1line
output_region_continue:
		movea.l	HIST_NEXT(a0),a0
		bra	output_region_loop
****************
history_normal:
		sf	d5				*  D5 : -r : reverse
		moveq	#0,d6				*  D6 : bit0=noeventno, bit1=notime
parse_option_loop1:
		tst.w	d1
		beq	history_default

		cmpi.b	#'-',(a0)
		bne	parse_option_done

		subq.w	#1,d1
		addq.l	#1,a0
parse_option_loop2:
		move.b	(a0)+,d0
		beq	parse_option_loop1

		cmp.b	#'h',d0
		beq	option_h_found

		cmp.b	#'r',d0
		beq	option_r_found

		cmp.b	#'t',d0
		bne	b_bad_arg

		bset	#1,d6
		bra	parse_option_loop2

option_h_found:
		moveq	#3,d6
		bra	parse_option_loop2

option_r_found:
		st	d5
		bra	parse_option_loop2

parse_option_done:
		cmp.w	#1,d1				*  引数が
		bhi	b_too_many_args			*    2つ以上あればエラー
		blo	history_default			*    1つも無ければ $history[1] を参照する
do_print_history:
		bsr	atou				*  数値をスキャンする
		tst.b	(a0)				*  最初の非数字がNULでなければ
		bne	badly_formed_number		*    エラー

		tst.l	d0
		bra	history_check_n

history_default:
		bsr	parse_history_value
history_check_n:
		bmi	badly_formed_number
		bne	history_inf

		move.l	d1,d0
		bra	history_start

history_inf:
		move.l	#$ffffffff,d0
history_start:
		movea.l	history_bot(a5),a0
		cmpa.l	#0,a0
		beq	history_done

		tst.b	d5				*  逆順か？
		bne	history_reverse

		* 正順
prhist_for_loop1:
		subq.l	#1,d0
		beq	prhist_for_loop2

		tst.l	HIST_PREV(a0)
		beq	prhist_for_loop2

		movea.l	HIST_PREV(a0),a0
		bra	prhist_for_loop1

prhist_for_loop2:
		bsr	prhist_1line
		beq	history_done

		movea.l	HIST_NEXT(a0),a0
		bra	prhist_for_loop2

		* 逆順
history_reverse:
prhist_rev_loop:
		subq.l	#1,d0
		bcs	history_done

		bsr	prhist_1line
		beq	history_done

		movea.l	HIST_PREV(a0),a0
		bra	prhist_rev_loop

history_done:
		moveq	#0,d0
		rts

b_too_many_args:
		bsr	too_many_args
		bra	history_usage

b_bad_arg:
		bsr	bad_arg
history_usage:
		lea	msg_usage,a0
		bsr	usage
		lea	msg_usage2,a0
		bra	enputs1
****************************************************************
prhist_1line:
		cmpa.l	#0,a0
		beq	prhist_1line_return

		movem.l	d0-d5/a0/a3,-(a7)
		movea.l	a0,a3
		move.l	current_eventno(a5),HIST_REFNO(a3)	*  参照ポインタをセットする
		moveq	#0,d1					*  数値は右詰めで出力
		moveq	#' ',d2					*  数値の pad はスペースで出力
		btst	#1,d6					*  タイムスタンプを出力しないなら
		bne	prhist_1line_1				*  スキップ
		*
		lea	space4,a0
		bsr	puts
		*
		moveq	#1,d3					*  少なくとも 1文字
		moveq	#2,d4					*  少なくとも 2桁
		move.l	HIST_TIME(a3),d5
		move.l	d5,d0
		lsr.l	#8,d0
		lsr.l	#8,d0
		and.l	#%11111,d0				*  時を
		bsr	printu					*  出力する
		moveq	#':',d0					*  ':' を
		bsr	putc					*  出力する
		move.l	d5,d0
		lsr.l	#8,d0
		and.l	#%111111,d0				*  分を
		bsr	printu					*  出力する
		moveq	#':',d0					*  ':' を
		bsr	putc					*  出力する
		move.l	d5,d0
		and.l	#%111111,d0				*  秒を
		bsr	printu					*  出力する
		lea	space2,a0				*  スペースを 2つ
		bsr	puts					*  出力する
		bsr	put_tab					*  タブを出力する
prhist_1line_1:
		btst	#0,d6					*  イベント番号を出力しないなら
		bne	prhist_1line_2				*  スキップ

		moveq	#6,d3					*  少なくとも 6文字
		moveq	#1,d4					*  少なくとも 1桁
		move.l	HIST_EVENTNO(a3),d0			*  イベント番号を
		bsr	printu					*  出力する
		bsr	put_tab					*  タブを出力する
prhist_1line_2:
		move.w	HIST_NWORDS(a3),d1			*  D1.W := このイベントの語数
		subq.w	#1,d1
		bcs	prhist_1line_done

		lea	HIST_BODY(a3),a0
		bra	prhist_1line_start

prhist_1line_loop:
		bsr	put_space				*  空白を出力する
		bsr	strfor1					*  次の語
prhist_1line_start:
		bsr	cputs					*  語を出力する
		dbra	d1,prhist_1line_loop
prhist_1line_done:
		bsr	put_newline				*  改行する
		movem.l	(a7)+,d0-d5/a0/a3
		cmpa.l	#0,a0
prhist_1line_return:
		rts
****************************************************************
.xdef parse_history_value

parse_history_value:
		lea	word_history,a0
		bsr	svartol
		bpl	parse_history_value_1

		*  オーバーフロー

		tst.l	d1
		bpl	parse_history_value_return_inf	*  正方向
parse_history_value_return_0:
		moveq	#0,d1
		bra	parse_history_value_ok

parse_history_value_1:
		cmp.l	#2,d0
		bls	parse_history_value_return_0	*  $history[1] は定義されていない

		cmp.l	#5,d0
		bne	parse_history_value_return_bad
parse_history_value_ok:
		moveq	#0,d0
		rts

parse_history_value_return_inf:
		moveq	#1,d0
		rts

parse_history_value_return_bad:
		moveq	#0,d1
		moveq	#-1,d0
		rts
****************************************************************
.if 0
hour_ampm:
		tst.b	flag_ampm(a5)
		beq	hour_ok

		cmp.l	#12,d0
		blo	hour_ok
		beq	hour_pm

		sub.l	#12,d0
hour_pm:
		bset	#31,d0
hour_ok:
		rts
.endif
****************************************************************
.data

option_x:	dc.b	'-x',0
msg_usage:	dc.b	'[-rht] [<イベント数>]',0
msg_usage2:	dc.b	'        history -x <開始番号>[-<終了番号>]',0
space4:		dc.b	'  '
space2:		dc.b	'  ',0
****************************************************************
.end
