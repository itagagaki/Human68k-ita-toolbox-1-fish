* fgetc.s
* Itagaki Fumihiko 23-Feb-91  Create.

.include doscall.h

*****************************************************************
* fgetc - ファイルから1文字読み取る
*
* CALL
*      D0.W   ファイル・ハンドル
*
* RETURN
*      D0.L   負: エラー・コード
*             正: 下位バイトは読み取った文字
*
*      CCR    TST.L D0
*****************************************************************
.xdef fgetc

fgetc:
		move.w	d0,-(a7)
		DOS	_FGETC
		addq.l	#2,a7
		tst.l	d0
		rts

.end
