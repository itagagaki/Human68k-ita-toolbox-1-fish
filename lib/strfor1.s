* strfor1.s
* Itagaki Fumihiko 18-Aug-91  Create.

****************************************************************
* strfor1 - 文字列を1つスキップする
*
* CALL
*      A0     文字列の先頭アドレス
*
* RETURN
*      A0     1つスキップしたアドレス
*****************************************************************
.xdef strfor1

strfor1:
		tst.b	(a0)+
		bne	strfor1

		rts

.end
