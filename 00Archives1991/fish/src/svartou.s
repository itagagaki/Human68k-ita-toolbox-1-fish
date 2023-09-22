* findsvar.s
* Itagaki Fumihiko 24-Sep-90  Create.

.text

****************************************************************
* svartou - シェル変数を探し、最初の要素を数値に変換する
*           無符合
*
* CALL
*      A0     変数名を指す
*
* RETURN
*      D0.L    0 : 変数が無い...D1:=0
*              1 : 要素が無い...D1:=0
*              2 : 単語が数字で始まっていない...D1:=0
*              3 : 数字以外の文字がある
*              4 : 成功
*             -1 : オーバーフローした
*
*      D1.L   値
*
*      CCR    TST.L D0
****************************************************************
.xdef svartou

svartou:
		movem.l	d2/a0,-(a7)
		moveq	#0,d1
		moveq	#0,d2
		bsr	find_shellvar
		beq	svartou_return		* 変数が無い ; return 0

		moveq	#1,d2
		addq.l	#2,a0
		tst.w	(a0)+
		beq	svartou_return		* 単語が無い ; return 1

		bsr	for1str
		moveq	#2,d2
		bsr	atou
		bmi	svartou_return		* 数字で始まっていない ; return 2

		moveq	#3,d2
		tst.b	(a0)
		bne	svartou_return		* 数字の後に文字がある ; return 3

		moveq	#-1,d2
		tst.l	d0
		bne	svartou_return		* オーバーフローした ; return -1

		moveq	#4,d2
svartou_return:
		move.l	d2,d0
		movem.l	(a7)+,d2/a0
		rts
****************************************************************
* svartol - シェル変数を探し、最初の要素を数値に変換する
*           符号付き
*
* CALL
*      A0     変数名を指す
*
* RETURN
*      D0.L    0 : 変数が無い...D1:=0
*              1 : 要素が無い...D1:=0
*              2 : 単語が数字で始まっていない...D1:=0
*              3 : 数字以外の文字がある
*              4 : 成功
*             -1 : オーバーフローした
*
*      D1.L   値
*
*      CCR    TST.L D0
****************************************************************
.xdef svartol

svartol:
		move.l	d2,-(a7)
		moveq	#-1,d2
		cmpi.b	#'-',(a0)
		beq	svartol_forward

		moveq	#0,d2
		cmpi.b	#'+',(a0)
		bne	svartol_svartou
svartol_forward:
		addq.l	#1,a0
svartol_svartou:
		bsr	svartou
		cmp.l	#3,d0
		blt	svartol_done

		tst.b	d2
		bpl	svartol_done

		neg.l	d1
		bmi	svartol_done

		moveq	#-1,d0
svartol_done:
		move.l	(a7)+,d2
		tst.l	d0
		rts

.end
