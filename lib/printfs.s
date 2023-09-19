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
*
* NOTE
*      シフトJIS文字は考慮しない
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
		bra	string_low_continue

string_high_loop:
		swap	d4
string_low_loop:
		move.b	(a0)+,d0
		jsr	(a1)
string_low_continue:
		dbra	d4,string_low_loop

		swap	d4
		dbra	d4,string_high_loop
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

		move.b	d2,d0
		bra	pad_low_continue

pad_high_loop:
		swap	d3
pad_low_loop:
		jsr	(a1)
pad_low_continue:
		dbra	d3,pad_low_loop

		swap	d3
		dbra	d3,pad_high_loop

		moveq	#0,d3
pad_return:
		rts
****************

.end
