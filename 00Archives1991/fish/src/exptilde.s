* exptilde.s
* Itagaki Fumihiko 30-Sep-90  Create.

.include limits.h

.text

****************************************************************
* expand_tilde_word - 語の中の ~ を展開する
*
* CALL
*      A0     ~ を含む語の先頭アドレス．語は ', " and/or \ によるクオートが可．
*             （長さは MAXWORDLEN 以内であること）
*
*      A1     展開するバッファのアドレス
*      D1.W   バッファの容量
*
* RETURN
*      A1     バッファの次の格納位置
*
*      D0.L   ０ならば成功
*             負数ならばエラー
*                  -1  バッファの容量を超えた
*
*      D1.L   下位ワードは残りバッファ容量
*             上位ワードは破壊
*****************************************************************
.xdef expand_tilde_word

expand_tilde_word:
		movem.l	d1/d6-d7/a0/a2,-(a7)
		move.w	d0,d7
		beq	expand_tilde_word_over

		move.b	#'~',d0
		bsr	qstrchr
		beq	just_copy
just_copy:


		move.w	d1,d6
		movea.l	a1,a2
		moveq	#0,d1
		bsr	unpack1
		tst.w	d0
		bne	unpack_word_error

		moveq	#0,d0
		move.w	d1,d0
unpack_word_return:
		move.w	d6,d1
		movem.l	(a7)+,d1/d6-d7/a0/a2
		rts

expand_tilde_word_over:
		moveq	#-1,d0
		bra	unpack_word_return

unpack_word_error:
		swap	d0
		clr.w	d0
		swap	d0
		neg.l	d0
		bra	unpack_word_return
