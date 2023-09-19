* fclose.s
* Itagaki Fumihiko 18-Aug-91  Create.

.include doscall.h

*****************************************************************
* fclose - ファイルをクローズする
*
* CALL
*      D0.W   ファイル・ハンドル
*
* RETURN
*      D0.L   OS のエラー・コード
*      CCR    TST.L D0
*****************************************************************
.xdef fclose

fclose:
		move.w	d0,-(a7)
		DOS	_CLOSE
		addq.l	#2,a7
		tst.l	d0
		rts

.end
