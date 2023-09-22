* itoa.s
* Itagaki Fumihiko 02-Nov-90  Create.

.text

****************************************************************
* itoa - convert signed long word to ascii decimal
*
* CALL
*      A0     buffer (12B)
*      D0.L   signed 32bit value
*
* RETURN
*      none.
*****************************************************************
.xdef itoa

itoa:
		tst.l	d0
		bpl	utoa

		movem.l	d0/a0,-(a7)
		neg.l	d0
		bsr	utoa
		bsr	skip_space
		move.b	#'-',-1(a0)
		movem.l	(a7)+,d0/a0
		rts

.end
