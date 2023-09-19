* headtail.s
* Itagaki Fumihiko 14-Aug-90  Create.

.include limits.h

.xref skip_root
.xref find_slashes

.text

****************************************************************
* headtail - パス名のファイル部の位置
*
* CALL
*      A0     パス名の先頭アドレス
*
* RETURN
*      A1     ファイル部のアドレス
*      D0.L   ドライブ＋ディレクトリ部の長さ（最後の / または \ の分を含む）
*      CCR    TST.L D0
*****************************************************************
.xdef headtail

headtail:
		move.l	a0,-(a7)
		jsr	skip_root
loop:
		movea.l	a0,a1
		jsr	find_slashes
		tst.b	(a0)+
		bne	loop

		movea.l	(a7)+,a0
		move.l	a1,d0
		sub.l	a0,d0
		rts
*****************************************************************

.end
