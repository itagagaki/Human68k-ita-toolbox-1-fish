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
*      オープンする前にドライブを検査する
*****************************************************************
.xdef tfopen

tfopen:
		move.w	d0,-(a7)
		move.l	a0,-(a7)
		jsr	drvchkp
		bmi	return

		DOS	_OPEN
return:
		addq.l	#6,a7
		tst.l	d0
		rts

.end
