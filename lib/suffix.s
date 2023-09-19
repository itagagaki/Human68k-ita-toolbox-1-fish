* suffix.s
* Itagaki Fumihiko 14-Aug-90  Create.

.xref strbot

****************************************************************
* suffix - ファイル名の拡張子部のアドレス
*
* CALL
*      A0     ファイル名の先頭アドレス
*
* RETURN
*      A0     拡張子部のアドレス（‘.’の位置．‘.’が無ければ最後の NUL を指す）
*      CCR    TST.B (A0)
*
* NOTE
*      ‘/’や‘\’はチェックしない．必要ならheadtailを呼んでから呼ぶのがよい
*****************************************************************
.xdef suffix

suffix:
		movem.l	d0/a1-a2,-(a7)
		movea.l	a0,a2
		jsr	strbot
		movea.l	a0,a1
search_suffix:
		cmpa.l	a2,a1
		beq	suffix_return

		cmpi.b	#'.',-(a1)
		bne	search_suffix

		movea.l	a1,a0
suffix_return:
		movem.l	(a7)+,d0/a1-a2
		tst.b	(a0)
		rts

.end
