* strlen.s
* Itagaki Fumihiko 10-Nov-90  Create.

.text

****************************************************************
* strlen - return length of string.
*
* CALL
*      A0     string pointer
*
* RETURN
*      D0.L   length of the string
*****************************************************************
.xdef strlen

strlen:
		move.l	a1,-(a7)
		movea.l	a0,a1
		bsr	strbot
		exg	a0,a1
		move.l	a1,d0
		sub.l	a0,d0
		move.l	(a7)+,a1
		rts

.end
