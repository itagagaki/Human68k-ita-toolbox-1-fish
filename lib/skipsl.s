* skipsl.s
* Itagaki Fumihiko 27-Mar-93  Create.

.text

****************************************************************
* skip_slashes - / と \ をスキップする
*
* CALL
*      A0     文字列
*
* RETURN
*      A0     最初の / でも \ でもない位置
*      D0.B   最初の / でも \ でもない文字
*      CCR    TST.B D0
*****************************************************************
.xdef skip_slashes

skip_slashes:
		move.b	(a0)+,d0
		cmp.b	#'/',d0
		beq	skip_slashes

		cmp.b	#'\',d0
		beq	skip_slashes

		tst.b	-(a0)
		rts

.end
