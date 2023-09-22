* unsetvar.s
* Itagaki Fumihiko 24-Sep-90  Create.

.text

****************************************************************
* unset_var - 変数を削除する
*
* CALL
*      A0     変数領域の先頭アドレス
*      A1     削除する変数名パターンを指す
*      D0.B   0 : シェル変数である
*
* RETURN
*      none
****************************************************************
.xdef unset_var

unset_var:
		movem.l	d0-d1/a0-a2,-(a7)
		move.b	d0,d1
		movea.l	a0,a2			* A2 : 変数領域の先頭アドレス
		addq.l	#8,a0
loop:
		tst.w	(a0)			* この変数が占めるバイト数
		beq	unset_var_return	* 0ならおしまい

		addq.l	#4,a0
		moveq	#0,d0
		bsr	strpcmp
		subq.l	#4,a0
		tst.l	d0
		bne	nomatch
****************
		movem.l	a0-a1,-(a7)
		tst.b	d1
		bne	delete_entry

		addq.l	#4,a0
		bsr	flagvarptr
		subq.l	#4,a0
		tst.l	d0
		beq	delete_entry

		movea.l	d0,a1
		clr.b	(a1)
delete_entry:
		movea.l	a0,a1
		adda.w	(a1),a1			* A1 : 次の変数のアドレス　（正しい）
		move.l	a2,d0
		add.l	4(a2),d0		* 最後の変数の次のアドレス
		sub.l	a1,d0
		bsr	memmove_inc
		clr.w	(a0)
		suba.l	a2,a0
		move.l	a0,4(a2)
		movem.l	(a7)+,a0-a1
		bra	loop
****************
nomatch:
		adda.w	(a0),a0			* 次の変数のアドレスをセット　（正しい）
		bra	loop			* 繰り返す
****************
unset_var_return:
		movem.l	(a7)+,d0-d1/a0-a2
		rts

.end
