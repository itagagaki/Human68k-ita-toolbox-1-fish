* strcpy.s
* Itagaki Fumihiko 16-Jul-90  Create.

.xref strmove

.text

****************************************************************
* strcpy - copy a string.
*
* CALL
*      A0     destination
*      A1     source (NUL-terminated string pointer)
*
* RETURN
*      D0.L   copied length (not counts NUL)
*****************************************************************
.xdef strcpy

strcpy:
		movem.l	a0-a1,-(a7)
		jsr	strmove
		move.l	a0,d0
		movem.l	(a7)+,a0-a1
		sub.l	a0,d0
		subq.l	#1,d0
		rts

.end
