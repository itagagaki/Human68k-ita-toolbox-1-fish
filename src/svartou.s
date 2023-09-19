* findsvar.s
* Itagaki Fumihiko 24-Sep-90  Create.

.xref atou
.xref for1str
.xref find_shellvar

.text

****************************************************************
sub1:
		moveq	#0,d1
		moveq	#0,d2
		bsr	find_shellvar
		beq	sub1_done			*  変数が無い ; return 0

		moveq	#1,d2
		addq.l	#2,a0
		tst.w	(a0)+
		beq	sub1_done			*  単語が無い ; return 1

		moveq	#2,d2
		bsr	for1str
		tst.b	(a0)
sub1_done:
		rts
****************************************************************
sub2:
		moveq	#3,d2
		bsr	atou
		bmi	sub2_done			*  数字で始まっていない ; return 3

		moveq	#4,d2
		tst.b	(a0)
		bne	sub2_done			*  数字の後に文字がある ; return 4

		moveq	#5,d2
		cmp.w	d2,d2
sub2_done:
		rts
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
*              2 : 要素が空文字列...D1:=0
*              3 : 単語が数字で始まっていない...D1:=0
*              4 : 数字以外の文字がある
*              5 : 成功
*             -1 : オーバーフローした
*
*      D1.L   値
*
*      CCR    TST.L D0
****************************************************************
.xdef svartou

svartou:
		movem.l	d2/a0,-(a7)
		bsr	sub1
		beq	svartou_return

		bsr	sub2
		bne	svartou_return

		tst.l	d0
		beq	sub2_done

		moveq	#-1,d2				*  オーバーフロー ; return -1
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
*              2 : 要素が空文字列...D1:=0
*              3 : 単語が数字または符号で始まっていない...D1:=0
*              4 : 数字以外の文字がある
*              5 : 成功
*             -1 : オーバーフローした
*
*      D1.L   値
*             オーバーフローの場合にも符号ビットが符号を表わす
*
*      CCR    TST.L D0
****************************************************************
.xdef svartol

svartol:
		movem.l	d2-d3/a0,-(a7)
		bsr	sub1
		beq	svartol_return

		moveq	#-1,d3
		cmpi.b	#'-',(a0)
		beq	svartol_skip_sign

		moveq	#1,d3
		cmpi.b	#'+',(a0)
		bne	svartol_atou
svartol_skip_sign:
		addq.l	#1,a0
svartol_atou:
		bsr	sub2
		bne	svartol_return

		tst.l	d0
		bne	svartol_overflow		*  オーバーフロー

		tst.l	d1
		bpl	svartol_1
svartol_overflow:
		bclr	#31,d1
		moveq	#-1,d2
svartol_1:
		tst.l	d3
		bpl	svartol_return

		neg.l	d1
svartol_return:
		move.l	d2,d0
		movem.l	(a7)+,d2-d3/a0
		rts
****************************************************************
.end
