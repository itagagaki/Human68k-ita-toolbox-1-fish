* isatty.s
* Itagaki Fumihiko 02-Jan-90  Create.

.include doscall.h

.text

****************************************************************
* isatty - is character device
*
* CALL
*      D0.W   file handle
*
* RETURN
*      D0.L   下位バイトが 0 ならばブロックデバイス
*             0x80 ならばキャラクタデバイス
*             上位は破壊
*
*      CCR    TST.B D0
*****************************************************************
.xdef isatty

isatty:
		move.w	d0,-(a7)
		clr.w	-(a7)
		DOS	_IOCTRL
		addq.l	#4,a7
		and.b	#$80,d0
		rts

.end
