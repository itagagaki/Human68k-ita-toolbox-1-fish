* strchr.s
* Itagaki Fumihiko 23-Sep-90  Create.

.xref _strchr

.text

****************************************************************
* strchr - 文字列からある文字を探し出す
*
* CALL
*      A0     文字列を指すポインタ
*
*      D0.W   検索文字
*             シフトJISコードまたは ANKコード
*             ANKコードは上位バイトを 0 とする
*
* RETURN
*      A0     最初に検索文字が現れる位置を指す
*             検索文字が見つからなかった場合には，最後のNUL文字を指す
*
*      CCR    TST.B (A0)
*****************************************************************
.xdef strchr

strchr:
		movem.l	d1,-(a7)
		moveq	#0,d1
		bsr	_strchr
		movem.l	(a7)+,d1
		rts

.end
