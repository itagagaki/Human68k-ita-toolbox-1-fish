* cmdhis.s
* This contains built-in command 'history'.
*
* Itagaki Fumihiko 23-Dec-90  Create.

.text

****************************************************************
*  Name
*       history - print history list
*
*  Synopsis
*       history [-hr] [行数]
*
*       -h   行番号無しで出力する
*       -r   逆順に出力する
****************************************************************

itoawork  = -12

.xdef cmd_history

cmd_history:
		link	a6,#itoawork
		moveq	#0,d4		* D4 : -h : hide line #
		moveq	#0,d5		* D5 : -r : reverse
sw_lp:
		tst.w	d0
		beq	his_n

		cmpi.b	#'-',(a0)
		bne	his_n

		subq.w	#1,d0
		addq.l	#1,a0
sw_lp1:
		move.b	(a0)+,d1
		beq	sw_lp

		cmp.b	#'h',d1
		beq	his_h

		cmp.b	#'r',d1
		bne	his_bad_arg
his_r:
		moveq	#1,d5
		bra	sw_lp1

his_h:
		moveq	#1,d4
		bra	sw_lp1

his_n:
		cmp.w	#1,d0			* 引数が
		bhi	his_too_many_args	* ２つ以上あればエラー
		blo	history_default		* １つも無ければ $history[1] を参照する

		bsr	atou			* 数値をスキャンする
		tst.b	(a0)			* 最初の非数字がNULでなければ
		bne	his_bad_arg		* エラー

		tst.l	d0
		bmi	his_bad_arg		* エラー
		bne	history_all		* オーバーフロー．．全行を表示

		bra	history_check_n

history_default:
		lea	word_history,a0
		bsr	svartol
		bmi	history_all		* オーバーフロー．．．全行を表示

		cmp.l	#1,d0
		bls	history_done		* $history[1] は定義されていない

		cmp.l	#4,d0
		beq	history_check_n

		bsr	badly_formed_number
		bra	history_return

history_check_n:
		move.l	d1,d0
		cmp.l	his_nlines_now,d0	* 現在の行数以下ならば
		bls	history_start		* ＯＫ
history_all:
		move.l	his_nlines_now,d0	* D0に現在の行数をセット
history_start:
		tst.l	d0
		beq	history_done

		move.l	his_toplineno,d1	* D1には
		add.l	his_nlines_now,d1	*   最終行の行番号＋１をセット
		movea.l	hiswork,a0
		add.l	his_end,a0		* A0には現在の履歴の末端のアドレスの先頭からのオフセットをセット
		tst.w	d5			* 逆順か？
		bne	history_reverse

		* 正順

		sub.l	d0,d1			* D1に表示する先頭の行の行番号を求める
		bsr	backup_history
prhist_for_loop:
		tst.w	(a0)			* この行のバイト数
		beq	history_done		* 0ならおしまい

		bsr	prhist_1line		* この行を表示する
		adda.w	(a0),a0			* ポインタを次の行に移動　（正しい）
		addq.l	#1,d1			* 行番号をインクリメント
		bra	prhist_for_loop		* 繰り返す

		* 逆順
history_reverse:
prhist_rev_loop:
		suba.w	-2(a0),a0		* ポインタを前の行に移動　（正しい）
		subq.l	#1,d1			* 行番号をデクリメント
		bsr	prhist_1line		* この行を表示する
		subq.l	#1,d0
		bne	prhist_rev_loop		* 表示行数分繰り返す
history_done:
		moveq	#0,d0
history_return:
		unlk	a6
		rts

his_too_many_args:
		bsr	too_many_args
		bra	history_usage

his_bad_arg:
		bsr	bad_arg
history_usage:
		lea	msg_usage,a0
		bsr	usage
		bra	history_return
****************************************************************
prhist_1line:
		movem.l	d0-d3/a1,-(a7)
		move.l	a0,-(a7)		* アドレスを待避
		tst.w	d4			* 行番号を表示しないならば
		bne	prhist_1line_1		* 行番号表示をスキップ

		move.l	d1,d0			* 行番号を
		moveq	#6,d2			* 少なくとも６桁
		moveq	#0,d3			* '0'埋め無しで
		lea	puts(pc),a1
		bsr	printu			* 表示する
		bsr	put_tab			* タブを表示する
prhist_1line_1:
		addq.l	#2,a0
		move.w	(a0)+,d1		* この行の語数をD1にセット
		beq	prhist_1line_done	* ０ならおしまい

		subq.w	#1,d1
		bra	prhist_1line_start
prhist_1line_loop:
		bsr	put_space		* 空白を表示する
		bsr	for1str			* 次の語
prhist_1line_start:
		bsr	cputs			* 語を表示する
		dbra	d1,prhist_1line_loop
prhist_1line_done:
		move.l	(a7)+,a0		* アドレスを戻す
		bsr	put_newline		* 改行する
		movem.l	(a7)+,d0-d3/a1
		rts

	if	0
*****************************************************************
* gethist - get history line address
*
* CALL
*      D0       line no.
*
* RETURN
*      D0.L	0 if found, otherwise 1
*      A0.L     address of the line
*
gethist:
		movea.l	hiswork,a0		* 履歴の先頭行のアドレスを
		addq.l	#4,a0			* A0にセット
		sub.l	his_toplineno,d0	* 先頭の行番号を引く
		blo	return_1		* それよりも若ければエラー

		bsr	forward_var		* D0行進める
		beq	return_1		* 行が無いならばエラー

		moveq	#0,d0
		rts

return_1:
		moveq	#1,d0
		rts

	endif

.data

msg_usage:	dc.b	'[ -h ] [ -r ] [ <イベント数> ]',0

.end
