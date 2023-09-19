* splitpath.s
* Itagaki Fumihiko 14-Aug-90  Create.

.xref strlen
.xref headtail
.xref suffix

****************************************************************
* split_pathname - パス名を分割する
*
* CALL
*      A0     パス名の先頭アドレス
*
* RETURN
*      A1     ディレクトリ部のアドレス
*      A2     ファイル部のアドレス
*      A3     拡張子部のアドレス（‘.’の位置．‘.’が無ければ最後の NUL を指す）
*      D0.L   ドライブ＋ディレクトリ部の長さ（最後の‘/’の分を含む）
*      D1.L   ディレクトリ部の長さ（最後の‘/’の分を含む）
*      D2.L   ファイル部（サフィックス部は含まない）の長さ
*      D3.L   サフィックス部の長さ（‘.’の分を含む）
*****************************************************************
.xdef split_pathname

split_pathname:
	*  A2 にファイル部の先頭アドレス
	*  D0 にドライブ＋ディレクトリ部の長さ（最後の / の分を含む）を得る

		jsr	headtail
		movea.l	a1,a2			*  A2   : ファイル部の先頭アドレス

	*  A1 にディレクトリ部の先頭アドレス
	*  D1 にディレクトリ部の長さ（最後の / の分を含む）を得る

		movea.l	a0,a1
		movem.l	d0/a0,-(a7)		*  D0 と A0 をセーブする
		move.l	d0,d1
		cmp.l	#2,d1
		blo	split_pathname_1

		cmpi.b	#':',1(a1)
		bne	split_pathname_1

		addq.l	#2,a1
		subq.l	#2,d1
split_pathname_1:
		movea.l	a2,a0
		jsr	suffix
		movea.l	a0,a3			*  A3   : サフィックス部のアドレス（‘.’から）
		jsr	strlen
		move.l	d0,d3			*  D3.L : サフィックス部の長さ（‘.’を含む）
		move.l	a3,d2
		sub.l	a2,d2			*  D2.L : ファイル部の長さ（サフィックス部は含まない）
split_pathname_return:
		movem.l	(a7)+,d0/a0		*  D0 と A0 を取り戻す
		rts

.end
