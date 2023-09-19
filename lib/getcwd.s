* getcwd.s
* Itagaki Fumihiko 14-Jul-90  Create.
* Itagaki Fumihiko 20-Aug-91  bsltosl ÇåƒÇ‘ÇÊÇ§Ç…ÇµÇΩÅD

.include doscall.h

.xref bsltosl

.text

****************************************************************
* getcwd - get current working directory name
*
* CALL
*      A0     buffer point
*
* RETURN
*      None.
*****************************************************************
.xdef getcwd

getcwd:
		movem.l	d0/a0,-(a7)
		DOS	_CURDRV
		add.b	#'A',d0
		move.b	d0,(a0)+
		move.b	#':',(a0)+
		move.b	#'/',(a0)+
		move.l	a0,-(a7)
		clr.w	-(a7)
		DOS	_CURDIR
		addq.l	#6,a7
		movem.l	(a7)+,d0/a0
		jmp	bsltosl

.end
