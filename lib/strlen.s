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
		move.l	a0,-(a7)
		move.l	a0,d0
loop:
		tst.b	(a0)+
		bne	loop

		subq.l	#1,a0
		sub.l	a0,d0
		neg.l	d0
		movea.l	(a7)+,a0
		rts

.end
