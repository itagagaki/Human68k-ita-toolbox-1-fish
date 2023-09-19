* strbot.s
* Itagaki Fumihiko 16-Jul-90  Create.

.xref strlen

.text

****************************************************************
* strbot - 文字列の末尾を得る
*
* CALL
*      A0     文字列の先頭アドレス
*
* RETURN
*      D0.L   文字列の長さ
*      A0     文字列の末尾(NUL)のアドレス
*****************************************************************
.xdef strbot

strbot:
		jsr	strlen
		lea	(a0,d0.l),a0
		rts

.end
