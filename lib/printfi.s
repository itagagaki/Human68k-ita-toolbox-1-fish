* printfi.s
* Itagaki Fumihiko 21-Apr-91  Create.

.xref strlen

.text

****************************************************************
* printfi - ロング・ワード値を書式に従って出力する
*
* CALL
*      D0.L   値
*      D1.L   bit 0 : 0=右詰め  1=左詰め
*      D2.B   右詰めのとき、左側の隙間を埋める文字コード
*      D3.L   最小フィールド幅（バイト数）
*      D4.L   少なくとも出力する数字の桁数
*      A0     値を文字列に変換するサブ・ルーチンのエントリー・アドレス
*             このサブ・ルーチンに対し，34Bのバッファの先頭アドレスを
*             A0に与えて呼び出す。D1-D4 はそのまま渡す．
*             全てのレジスタを保存するものでなければならない．
*      A1     文字の出力を行なうサブ・ルーチンのエントリー・アドレス
*             このサブ・ルーチンに対し、文字コードをD0.Bに与えて呼び出す．
*             全てのレジスタを保存するものでなければならない．
*      A2     prefixの先頭アドレス
*             0 ならば出力しない．
*
* RETURN
*      D0.L   出力した文字数
*****************************************************************
.xdef printfi

printfi:
		link	a6,#-34				*  文字列バッファを確保する
		movem.l	d3-d6/a0/a2-a3,-(a7)
		movea.l	a0,a3
		lea	-34(a6),a0			*  A0 : 文字列バッファの先頭アドレス
		jsr	(a3)				*  値を文字列に変換
		movea.l	a0,a3				*  A3 : 文字列バッファの先頭アドレス
	*
	*  A0 に、符号をとばして数字が始まる位置を求める
	*
		move.b	(a0)+,d0
		cmp.b	#'-',d0
		beq	with_sign

		cmp.b	#'+',d0
		beq	with_sign

		cmp.b	#' ',d0
		beq	with_sign
no_sign:
		subq.l	#1,a0
with_sign:
	*
	*  D4.L に追加すべき桁数を求める
	*
		jsr	strlen
		move.l	d0,d5				*  D5.L : 数字の桁数
		sub.l	d0,d4
		bhs	precpadlen_ok

		moveq	#0,d4
precpadlen_ok:
	*
	*  D6.L にprefixの長さを求める
	*
		moveq	#0,d6
		cmpa.l	#0,a2
		beq	prefixlen_ok

		exg	a0,a2
		jsr	strlen
		exg	a0,a2
		move.l	d0,d6
prefixlen_ok:
	*
	*  D3.L にpadすべきバイト数を求める
	*
		move.l	a0,d0
		sub.l	a3,d0				*  D0 = 符号の長さ
		add.l	d6,d0				*     + prefixの長さ
		add.l	d4,d0				*     + 追加桁数
		add.l	d5,d0				*     + 数字の桁数
		sub.l	d0,d3
		bcc	fieldpadlen_ok

		moveq	#0,d3
fieldpadlen_ok:
		add.l	d3,d0
		move.l	d0,d5				*  D5.L : 出力する総文字数

		btst	#0,d1
		bne	left_justify
	*
	*  右詰め．' 'でpad
	*
		cmp.b	#'0',d2
		beq	left_justify_zeropad

		move.b	d2,d0
		bsr	pad				*  フィールドをpadする
		bsr	sign_and_prefix			*  符号とprefixを出力する
		bsr	digits				*  数字桁を出力する
		bra	done

left_justify_zeropad:
	*
	*  右詰め．'0'でpad
	*
		bsr	sign_and_prefix			*  符号とprefixを出力する
		move.b	d2,d0
		bsr	pad				*  フィールドをpadする
		bsr	digits				*  数字桁を出力する
		bra	done

left_justify:
	*
	*  左詰め
	*
		bsr	sign_and_prefix			*  符号とprefixを出力する
		bsr	digits				*  数字桁を出力する
		moveq	#' ',d0				*  ' 'で
		bsr	pad				*  フィールドをpadする
done:
		move.l	d5,d0
		movem.l	(a7)+,d3-d6/a0/a2-a3
		unlk	a6
		rts
****************
sign_and_prefix:
		cmpa.l	a0,a3
		beq	prefix

		move.b	(a3),d0
		jsr	(a1)
prefix:
		tst.l	d6
		beq	prefix_done

		exg	a0,a2
		bsr	puts
		exg	a0,a2
prefix_done:
		rts
****************
digits:
		tst.l	d4
		beq	puts

		moveq	#'0',d0
		exg	d3,d4
		bsr	pad
		exg	d3,d4
puts:
		move.b	(a0)+,d0
		beq	puts_done

		jsr	(a1)
		bra	puts
****************
pad_high_loop:
		swap	d3
pad_low_loop:
		jsr	(a1)
pad:
		dbra	d3,pad_low_loop

		swap	d3
		dbra	d3,pad_high_loop
puts_done:
		rts
****************

.end
