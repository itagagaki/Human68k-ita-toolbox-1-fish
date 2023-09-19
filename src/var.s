* var.s
* Itagaki Fumihiko 26-Oct-91  Create.

.include ../src/var.h

.xref strlen
.xref strcmp
.xref strmove
.xref strfor1
.xref memmovi
.xref wordlistlen
.xref putc
.xref cputs
.xref put_tab
.xref put_newline
.xref echo
.xref free
.xref xfree
.xref xmalloc

.xref shellvar_top


.text

****************************************************************
* varsize - 変数のサイズを求める（ヘッダの分は含まない）
*
* CALL
*      A0     変数のヘッダのアドレス
*
* RETURN
*      D0.L   サイズ
****************************************************************
.xdef varsize

varsize:
		move.l	a0,-(a7)
		move.w	var_nwords(a0),d0
		addq.w	#1,d0
		lea	var_body(a0),a0
		bsr	wordlistlen
		movea.l	(a7)+,a0
		rts
****************************************************************
* freevar - 変数リストをすべて解放する
*
* CALL
*      A0     変数リストの根
*
* RETURN
*      none
****************************************************************
.xdef freevar

freevar:
		movem.l	d0/a0,-(a7)
freevar_loop:
		move.l	a0,d0
		beq	freevar_done

		movea.l	var_next(a0),a0
		bsr	free
		bra	freevar_loop

freevar_done:
		movem.l	(a7)+,d0/a0
		rts
****************************************************************
* dupvar - 変数（シェル変数，別名）を複製する
*
* CALL
*      A4     source BSS top
*      A5     destination BSS top
*      D0.W   根のポインタのBSSオフセット
*
* RETURN
*      D0.L   成功なら (A5,D0.W)．途中でメモリが不足したならば -1
*      CCR    TST.L D0
****************************************************************
.xdef dupvar

dupvar:
		movem.l	d1-d3/a0-a3,-(a7)
		move.w	d0,d3
		movea.l	(a4,d3.w),a2			*  A2 : source
		moveq	#0,d2				*  D2 : 複製したリストの根
dupvar_loop:
		cmpa.l	#0,a2
		beq	dupvar_done

		movea.l	a2,a0
		bsr	varsize
		move.l	d0,d1				*  D1.L : varsize
		add.l	#VAR_HEADER_SIZE,d0
		bsr	xmalloc
		beq	dupvar_fail

		movea.l	d0,a0
		tst.l	d2
		beq	dupvar_first

		move.l	a0,var_next(a3)
		bra	dupvar_1

dupvar_first:
		move.l	a0,d2
dupvar_1:
		movea.l	a0,a3
		clr.l	var_next(a3)
		move.w	var_nwords(a2),var_nwords(a3)
		lea	var_body(a2),a1
		lea	var_body(a3),a0
		move.l	d1,d0
		bsr	memmovi
		movea.l	var_next(a2),a2
		bra	dupvar_loop

dupvar_fail:
		movea.l	d2,a0
		bsr	freevar
		moveq	#-1,d0
		bra	dupvar_return

dupvar_done:
		move.l	d2,(a5,d3.w)
		move.l	d2,d0
dupvar_return:
		movem.l	(a7)+,d1-d3/a0-a3
		rts
****************************************************************
* findvar - 変数（シェル変数，別名）を探す
*
* CALL
*      A0     変数リストの根
*      A1     探す変数名を指す
*
* RETURN
*      A0     変数名よりも辞書的に前方に位置する最後の変数のアドレス
*             あるいは 0
*
*      D0.L   見つかった変数のアドレス
*             見つからなければ 0
*
*      CCR    TST.L D0
****************************************************************
.xdef findvar

findvar:
		move.l	a2,-(a7)
		suba.l	a2,a2
findvar_loop:
		cmpa.l	#0,a0
		beq	not_found

		lea	var_body(a0),a0
		bsr	strcmp
		lea	-var_body(a0),a0
		beq	match
		bhi	not_found

		movea.l	a0,a2
		movea.l	var_next(a2),a0
		bra	findvar_loop

match:
		move.l	a0,d0
findvar_done:
		movea.l	a2,a0
		movea.l	(a7)+,a2
		rts

not_found:
		moveq	#0,d0
		bra	findvar_done
****************************************************************
* find_shellvar - シェル変数を探す
*
* CALL
*      A0     探す変数名を指す
*
* RETURN
*      A0     見つかった場合：見つかった変数の先頭アドレス
*             見つからなかった場合：変数名よりも辞書的に後方である最初の変数の先頭アドレス
*                                   あるいは終端のアドレス
*
*      D0.L   見つかれば A0 と同じ値
*             見つからなければ 0
*
*      CCR    TST.L D0
****************************************************************
.xdef find_shellvar

find_shellvar:
		move.l	a1,-(a7)
		movea.l	a0,a1
		movea.l	shellvar_top(a5),a0
		bsr	findvar
		movea.l	(a7)+,a1
		rts
****************************************************************
.xdef get_shellvar
.xdef get_var_value

get_shellvar:
		bsr	find_shellvar
		beq	get_shellvar_return
get_var_value:
		movea.l	d0,a0
		moveq	#0,d0
		move.w	var_nwords(a0),d0
		lea	var_body(a0),a0
		bsr	strfor1
		tst.l	d0
get_shellvar_return:
		rts
****************************************************************
* allocvar - 変数ノードを確保する
*
* CALL
*      A1     変数名の先頭アドレス
*      A2     値の単語並びの先頭アドレス
*      D1.W   値の単語数
*
* RETURN
*      A0     破壊
*      A3     確保した変数ノードの先頭アドレス．確保できなかったなら 0
*      D0.L   A3 と同じ
*      D2.L   破壊
*      CCR    TST.L D0
****************************************************************
.xdef allocvar

allocvar:
		movea.l	a2,a0
		move.w	d1,d0
		bsr	wordlistlen
		move.l	d0,d2				*  D2.L : 新変数の値のサイズ
		movea.l	a1,a0
		bsr	strlen
		add.l	d2,d0
		add.l	#1+VAR_HEADER_SIZE,d0		*  D0.L : 新変数全体のサイズ
		bsr	xmalloc
		movea.l	d0,a3				*  A3 : 新変数の先頭を指す
		rts
****************************************************************
* entervar - 変数を登録する
*
* CALL
*      A0     親変数のアドレス（無ければ 0）
*      D0.L   旧変数のアドレス（無ければ 0）
*      A1     変数名の先頭アドレス
*      A2     値の単語並びの先頭アドレス
*      D1.W   値の単語数
*      D2.L   値のサイズ
*      A3     新変数のアドレス
*      A4     変数リストの根のアドレス
*
* RETURN
*      D0.L   新変数のアドレス
*      CCR    TST.L D0
****************************************************************
.xdef entervar

entervar:
		movem.l	d3-d4/a0-a1/a4,-(a7)
		move.l	d0,d4				*  D4.L : 見つかった旧変数のアドレス
		*
		*  A4 に親の子へのポインタのアドレスをセットする
		*
		move.l	a0,d3
		beq	no_prev

		lea	var_next(a0),a4
no_prev:
		*
		*  D3.L に新変数の子となる変数のアドレスをセットする
		*
		tst.l	d4
		beq	new

		movea.l	d4,a0
		move.l	var_next(a0),d3
		bra	set_next_done

new:
		move.l	(a4),d3
set_next_done:
		move.l	d3,var_next(a3)			*  新変数の子ポインタをセットする
		move.w	d1,var_nwords(a3)		*  値の単語数をセットする
		lea	var_body(a3),a0
		bsr	strmove				*  変数名をセットする
		movea.l	a2,a1
		move.l	d2,d0
		bsr	memmovi				*  値の単語並びをセットする

		move.l	a3,(a4)				*  新変数をリンクする
		move.l	d4,d0				*  旧変数を
		bsr	xfree				*  解放する

		move.l	a3,d0				*  新変数のアドレスを返す
		movem.l	(a7)+,d3-d4/a0-a1/a4
		rts
****************************************************************
* setvar - 変数を定義する
*
* CALL
*      A0     変数リストの根のアドレス
*      A1     変数名の先頭アドレス
*      A2     値の単語並びの先頭アドレス
*      D0.W   値の単語数
*
* RETURN
*      D0.L   セットした変数の先頭アドレス．
*             ただし領域が足りないためセットできなかったならば 0．
*      CCR    TST.L D0
*
* NOTE
*      セットする値の語並びのアドレスが変数の現在の値の
*      一部位であるときにも、正しく動作する。
****************************************************************
.xdef setvar

setvar:
		movem.l	d1-d2/a0/a3-a4,-(a7)
		move.w	d0,d1				*  D1.W : 新変数の値の語数
		movea.l	a0,a4				*  A4 : 変数リストの根のアドレス
		bsr	allocvar			*  A3 : 新変数のアドレス
		beq	setvar_return

		movea.l	(a4),a0
		bsr	findvar
		bsr	entervar
setvar_return:
		movem.l	(a7)+,d1-d2/a0/a3-a4
		rts
****************************************************************
* printvar - 変数の値を表示する
*
* CALL
*      A0     変数の値の先頭アドレス
*      D0.W   変数の要素数
*
* RETURN
*      無し
****************************************************************
.xdef print_var_value

print_var_value:
		movem.l	d0-d2/a1,-(a7)
		move.w	d0,d2
		cmp.w	#1,d2
		beq	print_var_value_start

		move.b	#'(',d0			* ( を
		bsr	putc			* 表示する
print_var_value_start:
		move.w	d2,d0
		lea	cputs(pc),a1
		bsr	echo

		cmp.w	#1,d2
		beq	print_var_value_done

		move.b	#')',d0			* ) を
		bsr	putc			* 表示する
print_var_value_done:
		movem.l	(a7)+,d0-d2/a1
		rts
****************************************************************
* print_var - 変数を表示する
*
* CALL
*      A0     変数領域の先頭アドレス
*
* RETURN
*      無し
****************************************************************
.xdef printvar

printvar:
		movem.l	d0/a0-a1,-(a7)
		movea.l	a0,a1
printvar_loop:
		cmpa.l	#0,a1
		beq	printvar_done

		lea	var_body(a1),a0
		bsr	cputs			*  変数名を表示する
		bsr	put_tab			*  水平タブを表示する
		bsr	strfor1			*  A0 : 変数の値のアドレス
		move.w	var_nwords(a1),d0	*  D0.W : 変数の値の語数
		bsr	print_var_value		*  変数の値を表示する
		bsr	put_newline		*  改行する
		movea.l	var_next(a1),a1		*  次の変数のポインタ
		bra	printvar_loop		*  繰り返す

printvar_done:
		movem.l	(a7)+,d0/a0-a1
		rts
****************************************************************

.end
