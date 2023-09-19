* pathname.s
* Itagaki Fumihiko 14-Aug-90  Create.
*
* This contains pathname controll routines.

.include limits.h
.include ../src/var.h

.xref strbot
.xref strlen
.xref strfor1
.xref headtail
.xref cat_pathname
.xref fish_getenv

.text

****************************************************************
* suffix - ファイル名の拡張子部のアドレス
*
* CALL
*      A0     ファイル名の先頭アドレス
*
* RETURN
*      A0     拡張子部のアドレス（‘.’の位置．‘.’が無ければ最後の NUL を指す）
*      CCR    TST.B (A0)
*
* NOTE
*      ‘/’や‘\’はチェックしない．
*****************************************************************
.xdef suffix

suffix:
		movem.l	d0/a1-a2,-(a7)
		movea.l	a0,a2
		bsr	strbot
		movea.l	a0,a1
search_suffix:
		cmpa.l	a2,a1
		beq	suffix_return

		cmpi.b	#'.',-(a1)
		bne	search_suffix

		movea.l	a1,a0
suffix_return:
		movem.l	(a7)+,d0/a1-a2
		tst.b	(a0)
		rts
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

		bsr	headtail
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
		bsr	suffix
		movea.l	a0,a3			*  A3   : サフィックス部のアドレス（‘.’から）
		bsr	strlen
		move.l	d0,d3			*  D3.L : サフィックス部の長さ（‘.’を含む）
		move.l	a3,d2
		sub.l	a2,d2			*  D2.L : サフィックス部の長さ（サフィックス部は含まない）
split_pathname_return:
		movem.l	(a7)+,d0/a0		*  D0 と A0 を取り戻す
		rts
*****************************************************************
* make_sys_pathname - システム・ファイルのパス名を生成する
*
* CALL
*      A0     結果を格納するバッファ（MAXPATH+1バイト必要）
*      A1     $SYSROOT下のパス名
*
* RETURN
*      長さが MAXPATH を超えた場合には負数
*****************************************************************
.xdef make_sys_pathname

make_sys_pathname:
		movem.l	d0/a0-a3,-(a7)
		movea.l	a1,a2
		movea.l	a0,a3
		lea	word_sysroot,a0
		bsr	fish_getenv
		lea	str_nul,a1
		beq	make_sys_pathname_1

		movea.l	d0,a0
		lea	var_body(a0),a0
		bsr	strfor1
		movea.l	a0,a1
make_sys_pathname_1:
		movea.l	a3,a0
		bsr	cat_pathname
make_sys_pathname_return:
		movem.l	(a7)+,d0/a0-a3
		rts
*****************************************************************
.data

word_sysroot:		dc.b	'SYSROOT'
str_nul:		dc.b	0

*****************************************************************

.end
