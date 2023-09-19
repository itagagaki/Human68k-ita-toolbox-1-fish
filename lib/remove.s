* remove.s
* Itagaki Fumihiko 23-Feb-91  Create.

.include doscall.h

.text
*****************************************************************
* remove - ファイルを削除する
*
* CALL
*      A0     削除するファイルのパス名を指す
*
* RETRUN
*      D0.L   エラー・コード
*      CCR    TST.L D0
*
* NOTE
*      ドライブの検査は行わない
*****************************************************************
.xdef remove

remove:
		move.l	a0,-(a7)
		DOS	_DELETE
		addq.l	#4,a7
		tst.l	d0
		rts

.end
