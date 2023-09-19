* f_getenv.s
* Itagaki Fumihiko 18-Aug-91  Create.

.xref getenv

.xref envwork

.text

****************************************************************
* fish_getenv - FISH の環境変数ブロックから名前で変数を探す
*
* CALL
*      A0     検索する変数名の先頭アドレス
*
* RETURN
*      A0     見つかったならば環境ブロックの変数名の先頭を指す
*      D0.L   見つかったならば値の文字列の先頭アドレスを指す
*             見つからなければ 0
*      CCR    TST.L D0
*****************************************************************
.xdef fish_getenv

fish_getenv:
		move.l	a3,-(a7)
		movea.l	envwork(a5),a3
		bsr	getenv
		movea.l	(a7)+,a3
		rts

.end
