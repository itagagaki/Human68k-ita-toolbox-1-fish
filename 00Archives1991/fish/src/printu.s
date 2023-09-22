* printu.s
* Itagaki Fumihiko 22-Dec-90  Create.

itoawork = -12

.text

****************************************************************
* printu - 無符号ロング・ワード値を書式付き出力する
*
* CALL
*      D0.L   値
*      D2.W   少なくとも表示する桁数．
*      D3.B   0以外ならば' 'を'0'で埋める
*      A1     文字列の出力を行なうサブ・ルーチンのエントリー・アドレス
*             （このサブ・ルーチンに対し文字列のアドレスをA0に与えて呼び出す）
*
* RETURN
*      D0.L   出力した文字数
*****************************************************************
.xdef printu

printu:
		link	a6,#itoawork
		movem.l	d1/a0,-(a7)
		lea	itoawork(a6),a0
		bsr	utoa
		moveq	#10,d1
		sub.w	d2,d1
		bcs	printu_head_ok
printu_find_head:
		move.b	(a0),d0
		bsr	isspace
		bne	printu_head_ok

		addq.l	#1,a0
		dbra	d1,printu_find_head
printu_head_ok:
		tst.b	d3
		beq	printu_fill_ok

		bsr	zerofill
printu_fill_ok:
		jsr	(a1)
		bsr	strlen
		movem.l	(a7)+,d1/a0
		unlk	a6
		rts

.end
