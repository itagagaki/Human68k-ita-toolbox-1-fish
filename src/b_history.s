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
.xref cputs
.xref enputs1
.xref printfi
.xref put_space
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
.xref flag_ampm

.text

****************************************************************
*  Name
*       history - print history list
*
*  Synopsis
*       history [ -hr ] [ <イベント数> ]
*
*       -h   イベント番号や時刻無しで出力する
*       -r   逆順に出力する
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

		st	d4				*  イベント番号や時刻は表示しない
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
		sf	d4				*  D4 : -h : hide line #
		sf	d5				*  D5 : -r : reverse
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
		bne	b_bad_arg
option_r_found:
		st	d5
		bra	parse_option_loop2

option_h_found:
		st	d4
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

		movem.l	d0-d4/a0-a2,-(a7)
		move.l	current_eventno(a5),HIST_REFNO(a0)	*  参照ポインタをセットする
		tst.b	d4					*  イベント番号・時刻を表示しないならば
		bne	prhist_1line_1				*    表示ルーチンをスキップ
		*
		movea.l	a0,a2
		lea	utoa(pc),a0				*  unsigned -> decimal で
		lea	putc(pc),a1				*  標準出力に
		moveq	#0,d2					*  右詰めで
		*
		moveq	#'0',d3					*  pad は '0' で
		moveq	#2,d1					*  少なくとも 2桁
		move.l	HIST_TIME(a2),d4
		move.l	d4,d0
		lsr.l	#8,d0
		lsr.l	#8,d0
		and.l	#%11111,d0				*  ［時］を
		bsr	printfi					*  表示する
		moveq	#':',d0					*  ':' を
		jsr	(a1)					*  表示する
		move.l	d4,d0
		lsr.l	#8,d0
		and.l	#%111111,d0				*  ［分］を
		bsr	printfi					*  表示する
		moveq	#':',d0					*  ':' を
		jsr	(a1)					*  表示する
		move.l	d4,d0
		and.l	#%111111,d0				*  ［秒］を
		bsr	printfi					*  表示する
		bsr	put_space				*  ' 'を表示する
		bsr	put_space				*  ' 'を表示する
		*
		moveq	#' ',d3					*  pad は空白で
		moveq	#6,d1					*  少なくとも 6桁
		move.l	HIST_EVENTNO(a2),d0			*  イベント番号を
		bsr	printfi					*  表示する
		bsr	put_space				*  ' 'を表示する
		bsr	put_space				*  ' 'を表示する
		movea.l	a2,a0
prhist_1line_1:
		move.w	HIST_NWORDS(a0),d1			*  D1.W := このイベントの語数
		subq.w	#1,d1
		bcs	prhist_1line_done

		lea	HIST_BODY(a0),a0
		bra	prhist_1line_start

prhist_1line_loop:
		bsr	put_space				*  空白を表示する
		bsr	strfor1					*  次の語
prhist_1line_start:
		bsr	cputs					*  語を表示する
		dbra	d1,prhist_1line_loop
prhist_1line_done:
		bsr	put_newline				*  改行する
		movem.l	(a7)+,d0-d4/a0-a2
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
****************************************************************
.data

option_x:	dc.b	'-x',0
msg_usage:	dc.b	'[ -hr ] [ <イベント数> ]',0
msg_usage2:	dc.b	'        history -x <開始番号>[-<終了番号>]',0
****************************************************************
.end
