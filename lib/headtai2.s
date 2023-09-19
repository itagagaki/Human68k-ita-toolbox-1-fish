* headtai2.s
* Itagaki Fumihiko 27-Mar-93  Create.

.include limits.h

.xref skip_root
.xref skip_slashes
.xref find_slashes

.text

****************************************************************
* headtail2 - パス名のファイル部の位置
*
* CALL
*      A0     パス名の先頭アドレス
*
* RETURN
*      A1     ファイル部のアドレス
*      D0.L   ドライブ＋ディレクトリ部の長さ（最後の / または \ の分を含む）
*      CCR    TST.L D0
*
* DESCRIPTION
*      /foo/bar/ のような場合には bar をディレクトリ部ではなく
*      ファイル部とする．
*****************************************************************
.xdef headtail2

headtail2:
		move.l	a0,-(a7)
		jsr	skip_root
		jsr	skip_slashes
loop:
		movea.l	a0,a1
		jsr	find_slashes
		jsr	skip_slashes
		bne	loop

		movea.l	(a7)+,a0
		move.l	a1,d0
		sub.l	a0,d0
		rts
*****************************************************************

.end
