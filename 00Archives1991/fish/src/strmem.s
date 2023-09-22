* strmem.s
* Itagaki Fumihiko 16-Jul-90  Create.

.text

****************************************************************
* strmem - 文字列からあるパターンを探し出す
*
* CALL
*      A0     文字列を指すポインタ
*      A1     検索パターンの先頭アドレス
*      D0.L   検索パターンのバイト数
*      D1.B   0 以外ならば、ANK英文字の大文字と小文字を区別しない
*
* RETURN
*      D0.L   見つかったアドレス．見つからなければ0
*      CCR    TST.L D0
*
* DESCRIPTION
*      文字列中のシフトＪＩＳ文字も考慮している
*****************************************************************
.xdef strmem

strmem:
		movem.l	d2-d3/a0/a2,-(a7)
		move.l	d0,d2		* D2.L : 照合パターンの長さ
		beq	strmem_found	* 0 ならば文字列の先頭を返す

		bsr	strlen
		move.l	d0,d3		* 文字列の長さから
		sub.l	d2,d3		* 照合パターンの長さを引く
		bcs	strmem_fail	* 照合パターンより文字列が短いなら見つかるわけはない
strmem_loop:
		move.l	d2,d0
		bsr	memxcmp
		beq	strmem_found

		subq.l	#1,d3
		bcs	strmem_fail

		move.b	(a0)+,d0
		bsr	issjis
		bne	strmem_loop

		subq.l	#1,d3
		bcs	strmem_fail

		addq.l	#1,a0
		bra	strmem_loop

strmem_fail:
		suba.l	a0,a0
strmem_found:
		move.l	a0,d0
strmem_return:
		movem.l	(a7)+,d2-d3/a0/a2
		rts

.end
