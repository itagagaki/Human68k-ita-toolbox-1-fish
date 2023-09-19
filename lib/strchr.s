* strchr.s
* Itagaki Fumihiko 24-Aug-91  Create.

.text

****************************************************************
* strchr - 文字列からANK文字を探し出す
*
* CALL
*      A0     文字列の先頭アドレス
*      D0.B   検索文字（ANK）
*
* RETURN
*      A0     最初に検索文字が現れる位置を指す
*             検索文字が見つからなかった場合には，最後のNUL文字を指す
*
*      CCR    TST.B (A0)
*
* NOTE
*      シフトJISコードは考慮していない
*****************************************************************
.xdef strchr

strchr:
		move.l	d1,-(a7)
strchr_loop:
		move.b	(a0)+,d1
		beq	strchr_done

		cmp.b	d0,d1
		bne	strchr_loop
strchr_done:
		move.l	(a7)+,d1
		tst.b	-(a0)
		rts

.end
