* _strchr.s
* Itagaki Fumihiko 23-Sep-90  Create.

.xref scanchar2

.text

****************************************************************
* _strchr - 文字列からある文字を探し出す
*
* CALL
*      A0     文字列を指すポインタ
*
*      D0.W   検索文字
*             シフトJISコードまたは ANKコード
*             ANKコードは上位バイトを 0 とする
*
*      D1.B   1 ならば 文字列中の \ の次の文字は無視する
*
* RETURN
*      A0     最初に検索文字が現れる位置を指す
*             検索文字が見つからなかった場合には，最後のNUL文字を指す
*
*      CCR    TST.B (A0)
*****************************************************************
.xdef _strchr

_strchr:
		movem.l	d2/a1,-(a7)
		move.w	d0,d2
_strchr_loop:
		movea.l	a0,a1
		bsr	scanchar2
		beq	_strchr_eos

		cmp.w	d2,d0
		beq	_strchr_found

		tst.b	d1
		beq	_strchr_loop

		cmp.w	#'\',d0
		bne	_strchr_loop

		bsr	scanchar2
		bne	_strchr_loop
_strchr_eos:
		lea	-1(a0),a1
_strchr_found:
		movea.l	a1,a0
		move.w	d2,d0
		tst.b	(a0)
		movem.l	(a7)+,d2/a1
		rts

.end
