* evalvar.s
* Itagaki Fumihiko 10-Oct-90  Create.

.text

****************************************************************
* eval_var - 変数の値を得る
*
* CALL
*      A0     探す変数名を指す
*
* RETURN
*      A0     単語並びの先頭アドレス
*             変数が見つからなければ探した変数名
*
*      D0.L   値の単語数
*             変数が見つからなければ -1
*
*      CCR    TST.L D0
****************************************************************
.xdef eval_var

eval_var:
		move.l	a0,-(a7)
		bsr	find_shellvar
		movea.l	(a7)+,a0
		beq	try_env

		movea.l	d0,a0
		addq.l	#2,a0
		moveq	#0,d0
		move.w	(a0)+,d0
		bsr	for1str
		tst.l	d0
		rts

try_env:
		movem.l	a0-a1,-(a7)
		movea.l	a0,a1
		movea.l	envwork,a0
		bsr	getenv
		movem.l	(a7)+,a0-a1
		beq	undefined

		movea.l	d0,a0
		moveq	#1,d0
		tst.b	(a0)
		bne	return

		moveq	#0,d0
return:
		rts

undefined:
		moveq	#-1,d0
		rts

.end
