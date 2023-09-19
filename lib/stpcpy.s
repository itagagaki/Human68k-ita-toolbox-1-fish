* stpcpy.s
* Itagaki Fumihiko 16-Jul-90  Create.

.xref strmove

.text

****************************************************************
* stpcpy - copy a string.
*
* CALL
*      A0     destination
*      A1     source (NUL-terminated string pointer)
*
* RETURN
*      A0     points copied NUL of destination
*      D0.L   copied length (not counts NUL)
*****************************************************************
.xdef stpcpy

stpcpy:
		move.l	a1,-(a7)
		jsr	strmove
		move.l	a1,d0
		movea.l	(a7)+,a1
		sub.l	a1,d0
		subq.l	#1,d0
		subq.l	#1,a0
		rts

.end
