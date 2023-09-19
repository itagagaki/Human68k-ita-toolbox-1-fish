* printfs.s
* Itagaki Fumihiko 21-Apr-91  Create.

.xref strlen

.text

****************************************************************
* printfs - 文字列を書式に従って出力する
*
* CALL
*      A0     出力する文字列の先頭アドレス
*      A1     文字の出力を行なうサブ・ルーチンのエントリー・アドレス
*             文字コードをD0.Bに与えてこのサブ・ルーチンを呼び出す．
*             すべてのレジスタを保存するものでなければならない．
*      D1.L   bit 0 : 0=右詰め  1=左詰め
*      D2.B   右詰めのとき、左側の隙間を埋める文字コード
*      D3.L   最小フィールド幅（バイト数）
*      D4.L   最大出力文字（バイト）数
*
* RETURN
*      D0.L   出力した文字（バイト）数
*****************************************************************
.xdef printfs

printfs:
		movem.l	d1-d5/a0,-(a7)
	*
	*  D4.L := min(strlen(s), D4.L);	/*  D4.L : 文字列から出力するバイト数  */
	*
		jsr	strlen
		cmp.l	d0,d4
		blo	strlen_ok

		move.l	d0,d4
strlen_ok:
	*
	*  D3.L -= D4.L;
	*  if (D3.L < 0) D6.L = 0;		/*  D3.L : padするべきバイト数 */
	*
		sub.l	d4,d3
		bcc	padlen_ok

		moveq	#0,d3
padlen_ok:
		move.l	d4,d5
		add.l	d3,d5			*  D5.L : 出力する総文字数
	*
	*  左側をpadする
	*
		bsr	pad
	*
	*  文字列を出力する
	*
		tst.l	d4
		beq	string_done
string_loop:
		move.b	(a0)+,d0
		jsr	(a1)
		subq.l	#1,d4
		bne	string_loop
string_done:
	*
	*  右側をpadする
	*
		bchg	#0,d1			*  pad方向を反転
		moveq	#' ',d2			*  右側のpad文字は必ず空白
		bsr	pad
	*
	*  return 出力バイト数
	*
		move.l	d5,d0
		movem.l	(a7)+,d1-d5/a0
		rts
****************
pad:
		btst	#0,d1			*  pad方向が違うならば
		bne	pad_return		*  padしない

		tst.l	d3			*  padするバイト数が 0 ならば
		beq	pad_return		*  padしない

		move.b	d2,d0
pad_loop:
		jsr	(a1)
		subq.l	#1,d3
		bne	pad_loop
pad_return:
		rts
****************

.end
