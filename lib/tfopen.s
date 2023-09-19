* tfopen.s
* Itagaki Fumihiko 23-Feb-91  Create.

.include doscall.h

.xref drvchkp

.text

*****************************************************************
* tfopen - ファイルをオープンする
*
* CALL
*      A0     オープンするファイルのパス名
*      D0.W   オープン・モード
*
* RETURN
*      D0.L   負: エラー・コード
*             正: 下位ワードが、オープンしたファイルのファイル・ハンドルを示す
*
*      CCR    TST.L D0
*
* NOTE
*      オープンする前にドライブが読み込み可能かどうか検査する
*      （ライトプロテクトは検査しない）
*****************************************************************
.xdef tfopen

tfopen:
		move.w	d0,-(a7)
		move.l	a0,-(a7)
		bclr	#31,d0
		and.b	#15,d0
		beq	tfopen_1

		bset	#31,d0
tfopen_1:
		jsr	drvchkp
		bmi	return

		DOS	_OPEN
return:
		addq.l	#6,a7
		tst.l	d0
		rts

.end
