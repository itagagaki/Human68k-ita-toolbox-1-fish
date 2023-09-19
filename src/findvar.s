* findvar.s
* Itagaki Fumihiko 24-Sep-90  Create.

.xref strcmp

.xref shellvar

.text

****************************************************************
* find_var - 変数（シェル変数，別名）を探す
*
* CALL
*      A0     変数領域の先頭アドレス
*      A1     探す変数名を指す
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
.xdef find_var

find_var:
		addq.l	#8,a0
loop:
		tst.w	(a0)			* この変数が占めるバイト数
		beq	not_found		* 0ならおしまい

		addq.l	#4,a0
		bsr	strcmp
		beq	match
		bhi	over

		subq.l	#4,a0
		adda.w	(a0),a0			* 次の変数のアドレスをセット　（正しい）
		bra	loop			* 繰り返す

match:
		subq.l	#4,a0
		move.l	a0,d0
		rts

over:
		subq.l	#4,a0
not_found:
		moveq	#0,d0
		rts
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
		movea.l	shellvar(a5),a0
		bsr	find_var
		movea.l	(a7)+,a1
		rts
****************************************************************
.end
