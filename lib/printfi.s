* printi.s
* Itagaki Fumihiko 21-Apr-91  Create.

.xref printfs

.text

****************************************************************
* printfi - ロング・ワード値を書式に従って出力する
*
* CALL
*      D0.L   値
*
*      D1.L   少なくとも出力する文字数（バイト数）
*
*      D2.L   bit 0 : 0=右詰め  1=左詰め
*             bit 1 : 1= D1.Lの文字数（バイト数）を超えて出力しない
*
*      D3.B   右詰めのとき、左側の隙間を埋める文字コード
*
*      A0     値を文字列に変換するサブ・ルーチンのエントリー・アドレス
*             （このサブ・ルーチンに対し、値をD0.Lに、
*               34Bのバッファの先頭アドレスをA0に与えて呼び出す）
*
*      A1     文字の出力を行なうサブ・ルーチンのエントリー・アドレス
*             （このサブ・ルーチンに対し、文字コードをD0.Bに与えて呼び出す）
*
* RETURN
*      D0.L   出力した文字数
*****************************************************************
.xdef printfi

printfi:
		movem.l	d1/a0/a2,-(a7)
		movea.l	a0,a2
		link	a6,#-34			* 文字列バッファを確保する
		lea	-34(a6),a0		* A0 : 文字列バッファの先頭アドレス
		movem.l	d1-d7/a0-a6,-(a7)
		jsr	(a2)			* 値を文字列に変換
		movem.l	(a7)+,d1-d7/a0-a6
		btst	#0,d2
		bne	do_printfs

		cmp.b	#'0',d3
		bne	do_printfs

		cmpi.b	#'-',(a0)
		beq	with_sign

		cmpi.b	#'+',(a0)
		beq	with_sign
do_printfs:
		jsr	printfs
		bra	done

with_sign:
		tst.l	d1
		bne	with_sign_1

		btst	#1,d2
		bne	done
with_sign_1:
		move.b	(a0)+,d0
		jsr	(a1)
		subq.l	#1,d1
		jsr	printfs
		addq.l	#1,d0
done:
		unlk	a6
		movem.l	(a7)+,d1/a0/a2
		rts

.end
