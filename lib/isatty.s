* isatty.s
* Itagaki Fumihiko 02-Jan-90  Create.

.include doscall.h

.text

****************************************************************
* isatty - is a tty
*
* CALL
*      D0.W   ファイル・ハンドル
*
* RETURN
*      D0.L   ブロック・デバイスならば 0
*             キャラクタ・デバイスならば 0x80
*
*      CCR    TST.L D0
*****************************************************************
.xdef isatty

isatty:
		move.w	d0,-(a7)
		clr.w	-(a7)
		DOS	_IOCTRL
		addq.l	#4,a7
		and.l	#$80,d0
		rts

.end
