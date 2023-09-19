* printfs.s
* Itagaki Fumihiko 21-Apr-91  Create.

.xref strlen

.text

****************************************************************
* printfs - 文字列を書式に従って出力する
*
* CALL
*      A0     出力する文字列の先頭アドレス
*
*      A1     文字の出力を行なうサブ・ルーチンのエントリー・アドレス
*             文字コードをD0.Bに与えてこのサブ・ルーチンを呼び出す
*
*      D1.L   少なくとも出力する文字数（バイト数）
*
*      D2.L   bit 0 : 0=右詰め  1=左詰め
*             bit 1 : 1= D1.Lの文字数（バイト数）を超えて出力しない
*
*      D3.B   右詰めのとき、左側の隙間を埋める文字コード
*
* RETURN
*      D0.L   出力した文字数（バイト数）
*****************************************************************
.xdef printfs

printfs:
		movem.l	d1-d7/a0/a2-a6,-(a7)
		jsr	strlen
		move.l	d0,d4			* D4.L : 出力する文字列の文字数（バイト数）
		move.l	d1,d5
		sub.l	d0,d5			* D5.L : padする文字数（バイト数）
		bcc	pad_ok

		moveq	#0,d5
		btst	#1,d2
		beq	pad_ok

		move.l	d1,d4
pad_ok:
		move.l	d4,d1
		add.l	d5,d1			* D1.L : 出力する総文字数
		bsr	pad			* 左側をpadする
		*
		*  文字列を出力する
		*
		tst.l	d4
		beq	output_string_done

		movem.l	d1-d2/d5,-(a7)
output_string_loop:
		move.b	(a0)+,d0
		movem.l	d4/a0-a1,-(a7)
		jsr	(a1)
		movem.l	(a7)+,d4/a0-a1
		subq.l	#1,d4
		bne	output_string_loop

		movem.l	(a7)+,d1-d2/d5
output_string_done:
		bchg	#0,d2			* pad方向を反転
		moveq	#' ',d3			* 右側のpad文字は必ず空白
		bsr	pad			* 右側をpadする
		move.l	d1,d0
		movem.l	(a7)+,d1-d7/a0/a2-a6
		rts
*
*
*
pad:
		btst	#0,d2			* pad方向が違うならば
		bne	pad_done		* padしない

		tst.l	d5			* padする文字数が0ならば
		beq	pad_done		* padしない

		movem.l	d1-d2/d4,-(a7)
		move.b	d3,d0
pad_loop:
		movem.l	d0/d5/a1,-(a7)
		jsr	(a1)
		movem.l	(a7)+,d0/d5/a1
		subq.l	#1,d5
		bne	pad_loop

		movem.l	(a7)+,d1-d2/d4
pad_done:
		rts

.end
