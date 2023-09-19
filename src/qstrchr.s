* qstrchr.s
* Itagaki Fumihiko 23-Sep-90  Create.

.xref issjis

.text

****************************************************************
* qstrchr - 文字列からある文字を探し出す．
*           但し ' " ` の対の中の文字と \ の直後の文字は無視する．
*           ' " ` \ を探すことはできる．
*           文字列中のシフトＪＩＳ文字は無視する．
*           シフトＪＩＳ文字を探すことはできない．
*
* CALL
*      A0     文字列を指すポインタ
*      D0.B   検索文字
*
* RETURN
*      A0     最初に検索文字が現れる位置を指す．
*             検索文字が見つからなかった場合には，最後のNUL文字を指す．
*      CCR    TST.B (A0)
*****************************************************************
.xdef qstrchr

qstrchr:
		movem.l	d1-d2,-(a7)
		move.b	d0,d1
		moveq	#0,d2				* D2 : クオート・フラグ
qstrchr_loop:
		move.b	(a0)+,d0
		beq	qstrchr_break

		jsr	issjis
		beq	qstrchr_skip_one

		tst.b	d2
		beq	qstrchr_1

		cmp.b	d2,d0
		bne	qstrchr_loop
qstrchr_flip_quote:
		eor.b	d0,d2
		bra	qstrchr_loop

qstrchr_1:
		cmp.b	d1,d0
		beq	qstrchr_break

		cmp.b	#'"',d0
		beq	qstrchr_flip_quote

		cmp.b	#"'",d0
		beq	qstrchr_flip_quote

		cmp.b	#'`',d0
		beq	qstrchr_flip_quote

		cmp.b	#'\',d0
		bne	qstrchr_loop

		move.b	(a0)+,d0
		beq	qstrchr_break

		jsr	issjis
		bne	qstrchr_loop
qstrchr_skip_one:
		move.b	(a0)+,d0
		bne	qstrchr_loop
qstrchr_break:
		movem.l	(a7)+,d1-d2
		tst.b	-(a0)
		rts

.end
